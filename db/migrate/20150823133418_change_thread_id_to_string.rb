class ChangeThreadIdToString < ActiveRecord::Migration
  def self.up
  	change_column :email_threads, :threadId, :string
  end

  def self.down
  	change_column :email_threads, :threadId, :integer
  end
end
