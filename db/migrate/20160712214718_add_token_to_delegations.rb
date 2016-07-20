class AddTokenToDelegations < ActiveRecord::Migration
  def change
  	add_column :delegations, :token, :string
  	add_index :delegations, :token
  end
end
