class AddingLatestEmailDateToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :latest_email_date, :datetime
  end
end
