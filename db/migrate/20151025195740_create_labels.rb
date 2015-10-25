class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.references :user, index: true
      t.string :label_id
      t.string :name
      t.string :label_type

      t.timestamps
    end
    add_index :labels, :label_id
    add_index :labels, :label_type
  end
end
