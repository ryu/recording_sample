# recording_sample – 設計メモ

## 目的

このアプリは、**「更新履歴を安全・明示的に扱える Rails 設計」**を検証するためのサンプルである。

特に以下を重視している。

* 更新を **上書きしない**（履歴を自然に残す）
* polymorphic 関連を **読みやすく・安全に**使う
* 監査ログ（誰が・何をしたか）を **最小の仕組み**で残す
* ビジネスロジックが **モデルを読めば理解できる**こと

---

## 基本コンセプト

### 「同一性」と「内容」を分離する

このアプリでは、1つの論理的な対象を次の3つに分けて扱う。

| 概念        | 役割          |
| --------- | ----------- |
| Recording | 同一性（箱・ID）   |
| Document  | 内容のスナップショット |
| Event     | 何が起きたかの履歴   |

### なぜ分けるのか？

Rails でよくある設計では、

* `update` = 同じレコードを書き換える
* 履歴は別テーブルや PaperTrail に任せる

となりがちだが、
**「現在の状態」と「過去の状態」が同じレコードに混在する**ため、思考負荷が高い。

このアプリでは、

* **現在の状態** → Recording が指す最新の Document
* **過去の状態** → 古い Document + Event

と役割を完全に分離する。

---

## モデル構成

### Recording（同一性）

* 常に「今どの Document が最新か」を指す
* 論理削除（`deleted_at`）のみを持つ
* ビジネスユースケースの入口になる

主な責務：

* 新規作成
* 更新（新 Document を作って差し替え）
* 削除 / 復元
* Event を正しいタイミングで積む

```rb
Recording.create_with_document!
recording.update_with_new_document!
recording.soft_delete_with_event!
recording.restore_with_event!
```

> **原則**: Controller は Recording のメソッドを呼ぶだけ

---

### Document（内容のスナップショット）

* 実際の内容（title, body など）を持つ
* 更新のたびに **新しいレコードが作られる**
* 過去の Document は不変

```rb
Document.create!(...)
```

> 「履歴を残す」のではなく
> **「新しい状態を作る」**という発想

---

### Event（事実ログ）

* 「何が起きたか」を時系列で記録する
* ビジネスロジックは持たない
* 表示や判定用の **小さな helper メソッドのみ**を持つ

Event が持つ情報：

| カラム         | 意味                                       |
| ----------- | ---------------------------------------- |
| action_type | created / updated / destroyed / restored |
| actor_name  | 誰が操作したか（Userなしでも成立）                      |
| metadata    | 補助情報（差分など）                               |
| recordable  | その時点の Document                           |

---

## delegated_type を使う理由

`Recording` → `Document` の関連は polymorphic だが、
**素の polymorphic をそのまま使わない**。

```rb
delegated_type :recordable, types: %w[Document]
```

### 利点

* 使える型が **コード上で明示される**
* `Recording.documents` などのスコープが自動で生える
* 将来型を増やしても設計が壊れにくい

> polymorphic の柔軟さ + 業務コード向けの安全性

---

## 更新の流れ（update の設計）

更新は「上書き」しない。

1. 古い Document を保持
2. 新しい Document を作成
3. Recording のポインタを差し替え
4. Event を積む

```rb
transaction do
  ensure_not_deleted!
  previous, document = build_new_document_and_swap!
  add_updated_event!
end
```

### 差分の扱い

* まずは `title` だけを差分対象にする
* metadata に最小情報だけ入れる

```rb
metadata: {
  "changed_fields" => ["title"]
}
```

> 本文全文や before/after を保存しない
> → 運用で破綻しないための判断

---

## Event は「最小」であるべき

Event は **監査ログ**であり、状態管理の主体ではない。

そのため：

* enum は使わない（文字列 + 定数）
* metadata は自由だが **必須にしない**
* 表示用ロジックだけを Event に寄せる

```rb
event.action_label
event.title_changed?
event.recordable_title
event.actor_label
```

View は **domain の言葉だけ**を使う。

---

## 37signals 的な判断基準

この設計では、次を意識している。

* 魔法より **明示**
* 抽象化より **具体**
* 再利用より **理解しやすさ**
* 完璧より **今ちょうどいい最小**

その結果：

* Service Object は作らない
* Concern は「Event書き込み」など責務が明確な部分だけ
* public API は **短く、読めば分かる**

---

## この設計が向いているケース

* 更新履歴を確実に残したい
* 誰が何をしたかを追えるようにしたい
* 複雑な監査要件はまだない
* Rails 標準の流儀を活かしたい

---

## 今後の拡張余地

* delegated_type に別の型を追加
* metadata に request_id / source を追加
* Event の summary 化
* User 導入時に actor_name → actor_id へ移行

---

## まとめ

このアプリは、

> **「履歴を扱う責務を、Rails らしい形で分離した最小構成」**

を目指したサンプルである。

* Recording は「今」
* Document は「状態」
* Event は「事実」

この3つを分けることで、
**更新・履歴・監査を同時にシンプルに扱える**設計になる。

## Anti-patterns

このアプリ（Recording / Document / Event 設計）を前提とした
**やりがちな失敗例と、その回避策**をまとめる。

---

### 1. Document を上書き更新してしまう

**例**

```rb
recording.recordable.update!(title: "new")
```

**問題**

* 過去の状態が失われる
* Event が残っても「その時点の内容」を復元できない

**回避策**

* 更新は必ず `Recording#update_with_new_document!` 経由にする
* Document は **不変（immutable）**として扱う

---

### 2. Event をコールバックで自動生成する

**例**

```rb
after_update :create_event
```

**問題**

* Event がいつ積まれるかコードから分からない
* トランザクション境界が不透明
* バッチや管理画面追加時に二重ログが起きやすい

**回避策**

* Event は **ユースケースメソッド内で明示的に作る**
* `Recording` に責務を集約する

---

### 3. Event を「状態の正」にしてしまう

**例**

* Event を再生して現在状態を求める

**問題**

* イベントソーシング化して複雑になる
* 検索・表示・復元が重くなる

**回避策**

* 現在状態は常に `recording.recordable`
* Event は **監査・履歴専用**

---

### 4. metadata に巨大なデータを入れる

**例**

```rb
metadata: { before: old_body, after: new_body }
```

**問題**

* DB が肥大化する
* 監査ログが読めなくなる
* SQLite では特に致命的

**回避策**

* 最初は `changed_fields` のみ
* 必要なら `excerpt` や `hash` 程度に留める

---

### 5. action_type を enum 化して魔法を増やす

**問題**

* 追加のたびに migration が必要
* 分岐ロジックが散る

**回避策**

* 文字列 + 許可リスト（ACTIONS）で十分
* 増えるまで増やさない

---

### 6. delegated_type に型を詰め込みすぎる

**問題**

* Recording が「何でも箱」になる
* UI / Controller が型分岐だらけになる

**回避策**

* 「同一性として同列に扱えるか？」を言語化する
* 違和感が出たら Recording を分ける

---

### 7. soft delete を Document 側に持たせる

**問題**

* 「同一性の削除」か「特定版の削除」か曖昧
* 復元時の整合性が壊れる

**回避策**

* `deleted_at` は Recording にのみ持たせる
* Document は常に残す

---

### 8. 並び順を毎回 view で指定する

**例**

```erb
<% events.order(:created_at).each do |e| %>
```

**問題**

* 画面ごとに並び順がブレる

**回避策**

* `scope :recent` などを Event に定義
* view は `events.recent` だけ使う

---

### 9. View が metadata の構造を知っている

**例**

```erb
<%= e.metadata["changed_fields"] %>
```

**問題**

* metadata 変更で view が壊れる
* 表示ロジックが散る

**回避策**

* `Event#changed_fields`
* `Event#title_changed?` など **読み取りメソッド**を Event に置く

---

### 10. 例外を RuntimeError で雑に扱う

**問題**

* rescue が広すぎてバグを飲み込む
* 意図した失敗と想定外の失敗が区別できない

**回避策**

* `DeletedRecordingError` など用途別例外を定義
* controller ではその例外だけ rescue

---

### 11. すべてを Concern に逃がす

**問題**

* Recording を読んでもユースケースが分からない
* 探索コストが上がる

**回避策**

* Concern は「イベント書き込み」など責務が明確な部分だけ
* ユースケース本体は Recording に残す

---

### 12. 最新版を Event から推測する

**問題**

* Event が欠けると破綻する
* destroyed / restored が混ざると壊れる

**回避策**

* 最新状態は常に `recording.recordable`
* Event は補助情報

---

## 判断基準メモ

* metadata は **必須にしない**
* Event は **事実ログ以上の役割を持たせない**
* 「将来使うかも」で作らない
* 読めば意図が分かるコードを優先する

---

## Q&A – なぜこの設計にしたか

### Q1. なぜ「Recording / Document / Event」の3つに分けた？

**A. 「同一性」「状態」「事実」を分離して、考える対象を小さくするため。**

* **Recording**: “箱”＝同一性（ID）
* **Document**: 内容のスナップショット（状態）
* **Event**: 何が起きたか（監査）

こう分けると、

* “いま何が最新？” → `recording.recordable` を見るだけ
* “過去はどうだった？” → `events` と古い `Document` を辿るだけ

になり、更新履歴が自然に扱える。

---

### Q2. なぜ更新で Document を上書きしない？

**A. 履歴を「作る」側に寄せると、運用が壊れにくいから。**

上書き更新だと、履歴の整合性を保つために追加の仕組みが必要になりがち（差分保存、監査テーブル、PaperTrail 依存など）。
この設計は「新しい状態を新しいレコードとして作る」ので、履歴がシンプルになる。

---

### Q3. Event があるなら、Document の履歴は Event だけでよくない？

**A. Event は“事実”、Document は“状態”だから。**

Event は「更新した」という事実は残せるが、その時点の状態（title/body）を確実に復元できるとは限らない。
スナップショット（Document）が残っていることで、**過去状態の再現性**が強くなる。

---

### Q4. なぜ polymorphic ではなく delegated_type を使った？

**A. polymorphic の弱点（型が読み取りづらい）を潰したいから。**

delegated_type は、

* 使える型がコード上で明示される
* `Recording.documents` など型別スコープが生える
* 業務コードとして読みやすい

という利点があり、「polymorphic を安全に使う」ための落とし所になる。

---

### Q5. なぜ Event は enum ではなく文字列？

**A. “魔法を減らして、最小で回したい”から。**

enum は便利だが、追加・変更時の影響が大きくなりやすい。
この設計では、`ACTIONS` の許可リストで十分だと判断した。

---

### Q6. なぜ metadata を必須にしない？

**A. 最初から必須にすると、ログが運用都合で腐るから。**

metadata を必須にすると「とりあえず埋めるための値」が増えてノイズになる。
まずは空 `{}` を許容し、必要になったら `request_id` や `changed_fields` を足す方が長持ちする。

---

### Q7. なぜ metadata は “changed_fields” だけから始めた？

**A. 全文差分や before/after はコストが重く、壊れやすいから。**

* DB が肥大化しやすい（特に SQLite）
* 表示が遅くなる
* ログが読みにくくなる

最初は「何が変わったか」だけで十分なことが多いので、`["title"]` から始める。

---

### Q8. なぜ actor は User 参照ではなく actor_name（文字列）？

**A. 認証が無い段階でも監査ログを成立させたかったから。**

User が無い段階で `actor_id` を入れると設計が不自然になる。
まずは `actor_name` で「誰が」を残し、認証導入時に `actor_id` へ移行できるようにする。

---

### Q9. なぜ Event に helper（action_label / title_changed? など）を置いた？

**A. View から “構造の知識” を消したいから。**

View が `metadata["changed_fields"]` を直接触ると、仕様変更で壊れやすい。
Event に読み取りメソッドを置くと、View は “やりたい表示” だけ書ける。

---

### Q10. なぜロジックを Service Object に分離しない？

**A. まずは「モデルを読めば分かる」状態を優先したから。**

このアプリの規模では Service Object に分けると、

* 参照箇所が増える
* 追いづらくなる
* 変更コストが上がる

ため、ユースケースを `Recording` に集約した。

---

### Q11. Concern はどこまで使う？

**A. “責務が明確な部分だけ”。**

例えば「Event書き込み」のように、切り出す理由が明確なものだけを Concern にする。
ユースケース本体まで Concern に逃がすと読みにくくなる。

---

### Q12. 「削除」と「復元」を入れた理由は？

**A. 監査ログとして完結させるため。**

`deleted_at` は Recording に持たせ、Event で destroyed/restored を残すことで、

* 状態（deleted かどうか）
* 事実（いつ削除/復元したか）

の両方が追える。

---

### Q13. この設計はいつ別の設計に変えるべき？

**A. 次の兆候が出たら検討する。**

* types が増えすぎて UI/Controller が型分岐だらけ
* 監査要件が強くなり、actor が User/権限/署名まで必要
* 履歴が巨大で、スナップショット方式がコスト高（圧縮・アーカイブが必要）

その場合でも、今の設計は “説明できる最小” なので移行判断がしやすい。
