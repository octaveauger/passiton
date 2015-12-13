class LongerSubjectOfThread < ActiveRecord::Migration
  def self.up
  	change_column :email_threads, :subject, :text
  end

  def self.down
  	change_column :email_threads, :subject, :string
  end
end
