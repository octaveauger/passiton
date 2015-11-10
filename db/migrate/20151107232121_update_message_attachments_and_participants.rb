class UpdateMessageAttachmentsAndParticipants < ActiveRecord::Migration
  def up
  	add_column :message_attachments, :email_thread_id, :integer
  	change_column :message_attachments, :email_message_id, :string
  	add_index :message_attachments, :email_thread_id

  	add_column :message_participants, :email_thread_id, :integer
  	change_column :message_participants, :email_message_id, :string
  	add_index :message_participants, :email_thread_id
  end

  def down
  	remove_column :message_attachments, :email_thread_id
  	change_column :message_attachments, :email_message_id, :integer
  	
	remove_column :message_participants, :email_thread_id
  	change_column :message_participants, :email_message_id, :integer
  end
end
