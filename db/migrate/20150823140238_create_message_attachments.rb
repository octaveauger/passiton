class CreateMessageAttachments < ActiveRecord::Migration
  def change
    create_table :message_attachments do |t|
      t.references :email_message, index: true
      t.string :mimeType
      t.text :filename
      t.string :attachmentId
      t.integer :size

      t.timestamps
    end
  end
end
