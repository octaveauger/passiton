class CreateEmailHeaders < ActiveRecord::Migration
  def change
    create_table :email_headers do |t|
      t.references :email_message, index: true
      t.string :name
      t.text :value

      t.timestamps
    end
  end
end
