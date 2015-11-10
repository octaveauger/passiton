class AddOauthCancelledToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :oauth_cancelled, :boolean
  	add_index :users, :oauth_cancelled
  end
end
