class CreateAuthorisationSearches < ActiveRecord::Migration
  def change
    create_table :authorisation_searches do |t|
      t.references :authorisation, index: true
      t.string :scope

      t.timestamps
    end
    add_index :authorisation_searches, :scope
  end
end
