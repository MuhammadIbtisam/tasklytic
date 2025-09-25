class Tag < ApplicationRecord
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :name, presence: true, uniqueness: true
  before_save :downcase_name

  private

  def downcase_name
    self.name = name.downcase
  end
end
