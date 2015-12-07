class AddTokenToAuthorisations < ActiveRecord::Migration
  def change
  	add_column :authorisations, :token, :string
  	add_index :authorisations, :token
  end
end
