class AddFileToAttachments < ActiveRecord::Migration
  def change
  	add_column :message_attachments, :file, :string
  end
end
