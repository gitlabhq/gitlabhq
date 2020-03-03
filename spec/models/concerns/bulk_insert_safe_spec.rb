# frozen_string_literal: true

require 'spec_helper'

describe BulkInsertSafe do
  class BulkInsertItem < ApplicationRecord
    include BulkInsertSafe

    validates :name, presence: true
  end

  module InheritedUnsafeMethods
    extend ActiveSupport::Concern

    included do
      after_save -> { "unsafe" }
    end
  end

  module InheritedSafeMethods
    extend ActiveSupport::Concern

    included do
      after_initialize -> { "safe" }
    end
  end

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :bulk_insert_items, force: true do |t|
        t.string :name, null: true
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_insert_items, force: true
    end
  end

  def build_valid_items_for_bulk_insertion
    Array.new(10) do |n|
      BulkInsertItem.new(name: "item-#{n}")
    end
  end

  def build_invalid_items_for_bulk_insertion
    Array.new(10) do
      BulkInsertItem.new # requires `name` to be set
    end
  end

  it_behaves_like 'a BulkInsertSafe model', BulkInsertItem do
    let(:valid_items_for_bulk_insertion) { build_valid_items_for_bulk_insertion }
    let(:invalid_items_for_bulk_insertion) { build_invalid_items_for_bulk_insertion }
  end

  context 'when inheriting class methods' do
    it 'raises an error when method is not bulk-insert safe' do
      expect { BulkInsertItem.include(InheritedUnsafeMethods) }.to(
        raise_error(subject::MethodNotAllowedError))
    end

    it 'does not raise an error when method is bulk-insert safe' do
      expect { BulkInsertItem.include(InheritedSafeMethods) }.not_to raise_error
    end
  end

  context 'primary keys' do
    it 'raises error if primary keys are set prior to insertion' do
      items = build_valid_items_for_bulk_insertion
      items.each_with_index do |item, n|
        item.id = n
      end

      expect { BulkInsertItem.bulk_insert!(items) }.to raise_error(subject::PrimaryKeySetError)
    end
  end

  describe '.bulk_insert!' do
    it 'inserts items in the given number of batches' do
      items = build_valid_items_for_bulk_insertion
      expect(items.size).to eq(10)
      expect(BulkInsertItem).to receive(:insert_all!).twice

      BulkInsertItem.bulk_insert!(items, batch_size: 5)
    end

    it 'rolls back the transaction when any item is invalid' do
      # second batch is bad
      all_items = build_valid_items_for_bulk_insertion + build_invalid_items_for_bulk_insertion
      batch_size = all_items.size / 2

      expect do
        BulkInsertItem.bulk_insert!(all_items, batch_size: batch_size) rescue nil
      end.not_to change { BulkInsertItem.count }
    end

    it 'does nothing and returns true when items are empty' do
      expect(BulkInsertItem.bulk_insert!([])).to be(true)
      expect(BulkInsertItem.count).to eq(0)
    end
  end
end
