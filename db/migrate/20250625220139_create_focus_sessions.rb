class CreateFocusSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :focus_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration_minutes
      t.text :notes

      t.timestamps
    end
  end
end
