class AddHeaderFieldsInMessageAndAttachment < ActiveRecord::Migration
  def change
  	add_column :email_messages, :subject, :string
  	add_column :message_attachments, :inline, :boolean
  	add_index :message_attachments, :inline
  end
end
