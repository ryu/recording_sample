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
