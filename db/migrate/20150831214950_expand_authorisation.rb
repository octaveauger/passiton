class ExpandAuthorisation < ActiveRecord::Migration
  def change
  	add_column :authorisations, :status, :string
  	add_column :authorisations, :description, :text
	add_index :authorisations, :status
	remove_column :authorisations, :enabled
  end
end
