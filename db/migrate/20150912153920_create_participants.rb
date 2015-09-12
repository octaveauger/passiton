class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :domain
      t.string :company

      t.timestamps
    end
    add_index :participants, :email
    add_index :participants, :domain
    add_index :participants, :company
  end
end
