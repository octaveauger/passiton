class CreateEmailThreads < ActiveRecord::Migration
  def change
    create_table :email_threads do |t|
      t.references :authorisation
      t.integer :threadId
      t.text :snippet
      t.integer :historyId

      t.timestamps
    end
    add_index :email_threads, :threadId
  end
end
