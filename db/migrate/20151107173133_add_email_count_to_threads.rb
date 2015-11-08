class AddEmailCountToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :email_count, :integer
  end
end
