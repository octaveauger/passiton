class AddContentIdToAttachments < ActiveRecord::Migration
  def change
  	add_column :message_attachments, :content_id, :string
  end
end
