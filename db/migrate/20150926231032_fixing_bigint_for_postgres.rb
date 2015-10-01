class FixingBigintForPostgres < ActiveRecord::Migration
  def self.up
  	change_column :email_messages, :historyId, :string
  end

  def self.down
  	change_column :email_messages, :historyId, :integer
  end
end
