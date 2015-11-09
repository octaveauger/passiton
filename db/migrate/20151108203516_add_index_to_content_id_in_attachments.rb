class AddIndexToContentIdInAttachments < ActiveRecord::Migration
  def change
  	add_index :message_attachments, :content_id
  end
end
