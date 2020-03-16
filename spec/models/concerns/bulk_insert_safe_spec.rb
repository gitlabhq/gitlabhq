# frozen_string_literal: true

require 'spec_helper'

describe BulkInsertSafe do
  class BulkInsertItem < ApplicationRecord
    include BulkInsertSafe
    include ShaAttribute

    validates :name, :enum_value, :secret_value, :sha_value, presence: true

    ENUM_VALUES = {
      case_1: 1
    }.freeze

    sha_attribute :sha_value

    enum enum_value: ENUM_VALUES

    attr_encrypted :secret_value,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      insecure_mode: false
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
        t.integer :enum_value, null: false
        t.text :encrypted_secret_value, null: false
        t.string :encrypted_secret_value_iv, null: false
        t.binary :sha_value, null: false, limit: 20
      end
    end

    BulkInsertItem.reset_column_information
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_insert_items, force: true
    end
  end

  def build_valid_items_for_bulk_insertion
    Array.new(10) do |n|
      BulkInsertItem.new(
        name: "item-#{n}",
        enum_value: 'case_1',
        secret_value: 'my-secret',
        sha_value: '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
      )
    end
  end

  def build_invalid_items_for_bulk_insertion
    Array.new(10) do
      BulkInsertItem.new(
        name: nil, # requires `name` to be set
        enum_value: 'case_1',
        secret_value: 'my-secret',
        sha_value: '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
      )
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

    it 'items can be properly fetched from database' do
      items = build_valid_items_for_bulk_insertion

      BulkInsertItem.bulk_insert!(items)

      attribute_names = BulkInsertItem.attribute_names - %w[id]
      expect(BulkInsertItem.last(items.size).pluck(*attribute_names)).to eq(
        items.pluck(*attribute_names))
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
