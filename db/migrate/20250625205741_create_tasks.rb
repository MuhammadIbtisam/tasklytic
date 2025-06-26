class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :priority
      t.integer :estimated_minutes
      t.integer :status
      t.datetime :due_date

      t.timestamps
    end
    add_index :tasks, :status
    add_index :tasks, :priority
  end
end