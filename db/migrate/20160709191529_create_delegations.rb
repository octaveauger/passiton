class CreateDelegations < ActiveRecord::Migration
  def change
    create_table :delegations do |t|
      t.integer :manager_id
      t.integer :employee_id
      t.boolean :is_active

      t.timestamps
    end
    add_index :delegations, :manager_id
    add_index :delegations, :employee_id
    add_index :delegations, :is_active
  end
end
