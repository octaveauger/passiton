class AddIndexesToGmail < ActiveRecord::Migration
  def change
  	add_index :attachment_headers, :name
  	add_index :email_headers, :name
  end
end
