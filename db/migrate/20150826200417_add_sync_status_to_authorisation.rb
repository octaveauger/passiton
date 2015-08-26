class AddSyncStatusToAuthorisation < ActiveRecord::Migration
  def change
  	add_column :authorisations, :synced, :boolean
  	add_index :authorisations, :synced

  	add_index :authorisations, :enabled
  end
end
