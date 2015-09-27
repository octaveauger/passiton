class FixStringLengthOnAttachmentForPostgres < ActiveRecord::Migration
  def self.up
  	change_column :message_attachments, :attachmentId, :text
  end

  def self.down
  	change_column :message_attachments, :attachmentId, :string
  end
end
