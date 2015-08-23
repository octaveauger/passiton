class CreateEmailMessages < ActiveRecord::Migration
  def change
    create_table :email_messages do |t|
      t.references :email_thread, index: true
      t.string :messageId
      t.text :snippet
      t.integer :historyId
      t.integer :internalDate
      t.text :body_text
      t.text :body_html
      t.integer :sizeEstimate
      t.string :mimeType

      t.timestamps
    end
  end
end
