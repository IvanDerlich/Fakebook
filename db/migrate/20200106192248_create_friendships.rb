class CreateFriendships < ActiveRecord::Migration[6.0]
  def change
    create_table :friendships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :friend, index: true, foreign_key: { to_table: :users }
      t.boolean :confirmed
      t.timestamps null: false
    end
    change_column_default :friendships, :confirmed, false
  end
end