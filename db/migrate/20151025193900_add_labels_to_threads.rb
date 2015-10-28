class AddLabelsToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :labels, :text
  end
end
