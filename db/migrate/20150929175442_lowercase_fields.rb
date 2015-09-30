class LowercaseFields < ActiveRecord::Migration
  def change
  	rename_column :email_messages, :historyId, :history_id
  	rename_column :email_messages, :internalDate, :internal_date
  	rename_column :email_messages, :sizeEstimate, :size_estimate
  	rename_column :email_messages, :mimeType, :mime_type
  	rename_column :email_messages, :messageId, :message_id
  	rename_column :email_threads, :threadId, :thread_id
  	rename_column :email_threads, :historyId, :history_id
  	rename_column :message_attachments, :mimeType, :mime_type
  	rename_column :message_attachments, :attachmentId, :attachment_id
  end
end
