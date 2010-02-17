class CreateProductDownloads < ActiveRecord::Migration
  def self.up
    create_table :product_downloads do |t|
      t.timestamps
      
      t.string :title, :description, :attachment_file_name,
      :attachment_content_type
      t.integer :attachment_file_size, :download_limit,
      :downloads_count
    end
  end

  def self.down
    drop_table :product_downloads
  end
end
