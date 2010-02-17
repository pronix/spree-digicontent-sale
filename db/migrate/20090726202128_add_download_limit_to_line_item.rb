class AddDownloadLimitToLineItem < ActiveRecord::Migration
  def self.up
    add_column :line_items, :download_limit, :integer, :default => nil
    add_column :line_items, :download_code, :string
  end

  def self.down
    remove_column :line_items, :download_limit
    remove_column :line_items, :download_code
  end
end
