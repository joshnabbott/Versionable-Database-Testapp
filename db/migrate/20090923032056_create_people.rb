class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :name_first
      t.string :name_last
      t.date :birthdate
      t.integer :age
      t.boolean :is_living

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
