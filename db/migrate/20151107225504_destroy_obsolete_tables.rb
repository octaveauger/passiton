class DestroyObsoleteTables < ActiveRecord::Migration
  def up
    drop_table :email_messages
    drop_table :attachment_headers
    drop_table :email_headers
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
