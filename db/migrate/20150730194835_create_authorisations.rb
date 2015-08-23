class CreateAuthorisations < ActiveRecord::Migration
  def change
    create_table :authorisations do |t|
      t.integer :requester_id
      t.integer :granter_id
      t.string :scope

      t.timestamps
    end
    add_index :authorisations, :requester_id
    add_index :authorisations, :granter_id
    add_index :authorisations, [:requester_id, :granter_id]
  end
end
