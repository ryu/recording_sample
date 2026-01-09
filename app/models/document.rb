class Document < ApplicationRecord
  has_one :recording, as: :recordable, dependent: :destroy

  validates :title, presence: true
end
