class CreateSynchronisationErrors < ActiveRecord::Migration
  def change
    create_table :synchronisation_errors do |t|
      t.references :authorisation, index: true
      t.text :content, limit: 10.megabyte

      t.timestamps
    end
  end
end
