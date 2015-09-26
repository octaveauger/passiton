class FixingMoreIntegerForPostgres < ActiveRecord::Migration
  def self.up
  	change_column :email_messages, :internalDate, :string
  	change_column :email_messages, :sizeEstimate, :string
  end

  def self.down
  	change_column :email_messages, :internalDate, :integer
  	change_column :email_messages, :sizeEstimate, :integer
  end
end
