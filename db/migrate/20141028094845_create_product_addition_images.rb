class CreateProductAdditionImages < ActiveRecord::Migration
  def change
    create_table :product_addition_images do |t|
      t.references :product, index: true
      t.attachment :image

      t.timestamps
    end
  end
end
