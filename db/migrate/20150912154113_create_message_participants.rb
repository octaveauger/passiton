class CreateMessageParticipants < ActiveRecord::Migration
  def change
    create_table :message_participants do |t|
      t.references :email_message, index: true
      t.references :participant, index: true
      t.string :delivery

      t.timestamps
    end
    add_index :message_participants, :delivery
  end
end
