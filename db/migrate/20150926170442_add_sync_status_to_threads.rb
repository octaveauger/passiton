class AddSyncStatusToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :synced, :boolean
  	add_index :email_threads, :synced
  end
end
