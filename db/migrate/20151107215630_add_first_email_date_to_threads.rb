class AddFirstEmailDateToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :earliest_email_date, :datetime
  end
end
