class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.references :email_thread, index: true
      t.string :name

      t.timestamps
    end
    add_index :tags, :name
  end
end
