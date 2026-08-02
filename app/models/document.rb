class Document < ApplicationRecord
  has_one :recording, as: :recordable, dependent: :destroy

  validates :title, presence: true

  def changed_fields_from(other)
    %w[ title body ].select { |field| other[field] != self[field] }
  end
end
