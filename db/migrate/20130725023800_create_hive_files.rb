class CreateHiveFiles < ActiveRecord::Migration
  def change
    create_table :hive_files do |t|
      t.string :uuid
      t.string :name

      t.timestamps
    end
  end
end
