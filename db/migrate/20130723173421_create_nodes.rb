class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :uuid
      t.string :ip
      t.string :user_agent

      t.timestamps
    end
  end
end
