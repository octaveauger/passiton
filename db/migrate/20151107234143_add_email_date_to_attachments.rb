class AddEmailDateToAttachments < ActiveRecord::Migration
  def change
  	add_column :message_attachments, :email_date, :datetime
  end
end
