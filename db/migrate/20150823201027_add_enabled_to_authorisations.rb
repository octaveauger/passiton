class AddEnabledToAuthorisations < ActiveRecord::Migration
  def change
  	add_column :authorisations, :enabled, :boolean
  end
end
