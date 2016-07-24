class AddIsManagerToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :is_manager, :boolean, :default => false
  	add_index :users, :is_manager
  end
end
