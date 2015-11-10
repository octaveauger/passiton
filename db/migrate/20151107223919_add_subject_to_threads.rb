class AddSubjectToThreads < ActiveRecord::Migration
  def change
  	add_column :email_threads, :subject, :string
  end
end
