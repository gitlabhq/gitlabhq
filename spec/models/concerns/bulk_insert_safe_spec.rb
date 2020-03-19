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

    default_value_for :enum_value, 'case_1'
    default_value_for :secret_value, 'my-secret'
    default_value_for :sha_value, '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'

    def self.valid_list(count)
      Array.new(count) { |n| new(name: "item-#{n}") }
    end

    def self.invalid_list(count)
      Array.new(count) { new }
    end
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

        t.index :name, unique: true
      end
    end

    BulkInsertItem.reset_column_information
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_insert_items, force: true
    end
  end

  describe BulkInsertItem do
    it_behaves_like 'a BulkInsertSafe model', described_class do
      let(:valid_items_for_bulk_insertion) { described_class.valid_list(10) }
      let(:invalid_items_for_bulk_insertion) { described_class.invalid_list(10) }
    end

    context 'when inheriting class methods' do
      it 'raises an error when method is not bulk-insert safe' do
        expect { described_class.include(InheritedUnsafeMethods) }
          .to raise_error(described_class::MethodNotAllowedError)
      end

      it 'does not raise an error when method is bulk-insert safe' do
        expect { described_class.include(InheritedSafeMethods) }.not_to raise_error
      end
    end

    context 'primary keys' do
      it 'raises error if primary keys are set prior to insertion' do
        item = described_class.new(name: 'valid', id: 10)

        expect { described_class.bulk_insert!([item]) }
          .to raise_error(described_class::PrimaryKeySetError)
      end
    end

    describe '.bulk_insert!' do
      it 'inserts items in the given number of batches' do
        items = described_class.valid_list(10)

        expect(ActiveRecord::InsertAll).to receive(:new).twice.and_call_original

        described_class.bulk_insert!(items, batch_size: 5)
      end

      it 'items can be properly fetched from database' do
        items = described_class.valid_list(10)

        described_class.bulk_insert!(items)

        attribute_names = described_class.attribute_names - %w[id]
        expect(described_class.last(items.size).pluck(*attribute_names)).to eq(
          items.pluck(*attribute_names))
      end

      it 'rolls back the transaction when any item is invalid' do
        # second batch is bad
        all_items = described_class.valid_list(10) +
          described_class.invalid_list(10)

        expect do
          described_class.bulk_insert!(all_items, batch_size: 2) rescue nil
        end.not_to change { described_class.count }
      end

      it 'does nothing and returns true when items are empty' do
        expect(described_class.bulk_insert!([])).to be(true)
        expect(described_class.count).to eq(0)
      end
    end

    context 'when duplicate items are to be inserted' do
      let!(:existing_object) { described_class.create!(name: 'duplicate', secret_value: 'old value') }
      let(:new_object) { described_class.new(name: 'duplicate', secret_value: 'new value') }

      describe '.bulk_insert!' do
        context 'when skip_duplicates is set to false' do
          it 'raises an exception' do
            expect { described_class.bulk_insert!([new_object], skip_duplicates: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
          end
        end

        context 'when skip_duplicates is set to true' do
          it 'does not update existing object' do
            described_class.bulk_insert!([new_object], skip_duplicates: true)

            expect(existing_object.reload.secret_value).to eq('old value')
          end
        end
      end

      describe '.bulk_upsert!' do
        it 'updates existing object' do
          described_class.bulk_upsert!([new_object], unique_by: %w[name])

          expect(existing_object.reload.secret_value).to eq('new value')
        end
      end
    end
  end
end
