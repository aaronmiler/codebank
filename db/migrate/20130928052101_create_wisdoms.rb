class CreateWisdoms < ActiveRecord::Migration
  def change
    create_table :wisdoms do |t|
      t.string :title
      t.string :topic
      t.string :tags
      t.text :description
      t.text :contents

      t.timestamps
    end
  end
end
