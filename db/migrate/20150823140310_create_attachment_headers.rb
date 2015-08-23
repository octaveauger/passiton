class CreateAttachmentHeaders < ActiveRecord::Migration
  def change
    create_table :attachment_headers do |t|
      t.references :message_attachment, index: true
      t.string :name
      t.text :value

      t.timestamps
    end
  end
end
