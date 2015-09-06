class AddGuestToUser < ActiveRecord::Migration
  def change
  	add_column :users, :guest, :boolean, :default => true
  	add_index :users, :guest
  end
end
