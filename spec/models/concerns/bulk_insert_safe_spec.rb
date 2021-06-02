# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkInsertSafe do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :bulk_insert_parent_items, force: true do |t|
        t.string :name, null: false
      end

      create_table :bulk_insert_items, force: true do |t|
        t.string :name, null: true
        t.integer :enum_value, null: false
        t.text :encrypted_secret_value, null: false
        t.string :encrypted_secret_value_iv, null: false
        t.binary :sha_value, null: false, limit: 20
        t.jsonb :jsonb_value, null: false
        t.belongs_to :bulk_insert_parent_item, foreign_key: true, null: true

        t.index :name, unique: true
      end

      create_table :bulk_insert_items_with_composite_pk, id: false, force: true do |t|
        t.integer :id, null: true
        t.string :name, null: true
      end

      execute("ALTER TABLE bulk_insert_items_with_composite_pk ADD PRIMARY KEY (id,name);")
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :bulk_insert_items, force: true
      drop_table :bulk_insert_parent_items, force: true
      drop_table :bulk_insert_items_with_composite_pk, force: true
    end
  end

  BulkInsertParentItem = Class.new(ActiveRecord::Base) do
    self.table_name = :bulk_insert_parent_items
    self.inheritance_column = :_type_disabled

    def self.name
      table_name.singularize.camelcase
    end
  end

  let_it_be(:bulk_insert_parent_item) do
    BulkInsertParentItem.create!(name: 'parent')
  end

  let_it_be(:bulk_insert_item_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'bulk_insert_items'

      include BulkInsertSafe
      include ShaAttribute

      validates :name, :enum_value, :secret_value, :sha_value, :jsonb_value, presence: true

      belongs_to :bulk_insert_parent_item

      sha_attribute :sha_value

      enum enum_value: { case_1: 1 }

      attr_encrypted :secret_value,
        mode: :per_attribute_iv,
        algorithm: 'aes-256-gcm',
        key: Settings.attr_encrypted_db_key_base_32,
        insecure_mode: false

      default_value_for :enum_value, 'case_1'
      default_value_for :sha_value, '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
      default_value_for :jsonb_value, { "key" => "value" }

      def self.name
        'BulkInsertItem'
      end

      def self.valid_list(count, bulk_insert_parent_item: nil)
        Array.new(count) { |n| new(name: "item-#{n}", secret_value: 'my-secret', bulk_insert_parent_item: bulk_insert_parent_item) }
      end

      def self.invalid_list(count)
        Array.new(count) { new(secret_value: 'my-secret') }
      end
    end
  end

  describe 'BulkInsertItem' do
    it_behaves_like 'a BulkInsertSafe model' do
      let(:target_class) { bulk_insert_item_class.dup }
      let(:valid_items_for_bulk_insertion) { target_class.valid_list(10) }
      let(:invalid_items_for_bulk_insertion) { target_class.invalid_list(10) }
    end

    context 'when inheriting class methods' do
      let(:inherited_unsafe_methods_module) do
        Module.new do
          extend ActiveSupport::Concern

          included do
            after_save -> { "unsafe" }
          end
        end
      end

      let(:inherited_safe_methods_module) do
        Module.new do
          extend ActiveSupport::Concern

          included do
            after_initialize -> { "safe" }
          end
        end
      end

      it 'raises an error when method is not bulk-insert safe' do
        expect { bulk_insert_item_class.include(inherited_unsafe_methods_module) }
          .to raise_error(bulk_insert_item_class::MethodNotAllowedError)
      end

      it 'does not raise an error when method is bulk-insert safe' do
        expect { bulk_insert_item_class.include(inherited_safe_methods_module) }.not_to raise_error
      end
    end

    context 'primary keys' do
      it 'raises error if primary keys are set prior to insertion' do
        item = bulk_insert_item_class.new(name: 'valid', id: 10, secret_value: 'my-secret')

        expect { bulk_insert_item_class.bulk_insert!([item]) }
          .to raise_error(bulk_insert_item_class::PrimaryKeySetError)
      end
    end

    describe '.bulk_insert!' do
      it 'inserts items in the given number of batches' do
        items = bulk_insert_item_class.valid_list(10)

        expect(ActiveRecord::InsertAll).to receive(:new).twice.and_call_original

        bulk_insert_item_class.bulk_insert!(items, batch_size: 5)
      end

      it 'inserts items with belongs_to association' do
        items = bulk_insert_item_class.valid_list(10, bulk_insert_parent_item: bulk_insert_parent_item)

        bulk_insert_item_class.bulk_insert!(items, batch_size: 5)

        expect(bulk_insert_item_class.last(items.size).map(&:bulk_insert_parent_item)).to eq([bulk_insert_parent_item] * 10)
      end

      it 'items can be properly fetched from database' do
        items = bulk_insert_item_class.valid_list(10)

        bulk_insert_item_class.bulk_insert!(items)

        attribute_names = bulk_insert_item_class.attribute_names - %w[id created_at updated_at]
        expect(bulk_insert_item_class.last(items.size).pluck(*attribute_names)).to eq(
          items.pluck(*attribute_names))
      end

      it 'rolls back the transaction when any item is invalid' do
        # second batch is bad
        all_items = bulk_insert_item_class.valid_list(10) + bulk_insert_item_class.invalid_list(10)

        expect do
          bulk_insert_item_class.bulk_insert!(all_items, batch_size: 2) rescue nil
        end.not_to change { bulk_insert_item_class.count }
      end

      it 'does nothing and returns an empty array when items are empty' do
        expect(bulk_insert_item_class.bulk_insert!([])).to eq([])
        expect(bulk_insert_item_class.count).to eq(0)
      end

      context 'with returns option set' do
        context 'when is set to :ids' do
          it 'return an array with the primary key values for all inserted records' do
            items = bulk_insert_item_class.valid_list(1)

            expect(bulk_insert_item_class.bulk_insert!(items, returns: :ids)).to contain_exactly(a_kind_of(Integer))
          end
        end

        context 'when is set to nil' do
          it 'returns an empty array' do
            items = bulk_insert_item_class.valid_list(1)

            expect(bulk_insert_item_class.bulk_insert!(items, returns: nil)).to eq([])
          end
        end

        context 'when is set to anything else' do
          it 'raises an error' do
            items = bulk_insert_item_class.valid_list(1)

            expect { bulk_insert_item_class.bulk_insert!([items], returns: [:id, :name]) }
              .to raise_error(ArgumentError, "returns needs to be :ids or nil")
          end
        end
      end
    end

    context 'when duplicate items are to be inserted' do
      let!(:existing_object) { bulk_insert_item_class.create!(name: 'duplicate', secret_value: 'old value') }
      let(:new_object) { bulk_insert_item_class.new(name: 'duplicate', secret_value: 'new value') }

      describe '.bulk_insert!' do
        context 'when skip_duplicates is set to false' do
          it 'raises an exception' do
            expect { bulk_insert_item_class.bulk_insert!([new_object], skip_duplicates: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
          end
        end

        context 'when skip_duplicates is set to true' do
          it 'does not update existing object' do
            bulk_insert_item_class.bulk_insert!([new_object], skip_duplicates: true)

            expect(existing_object.reload.secret_value).to eq('old value')
          end
        end
      end

      describe '.bulk_upsert!' do
        it 'updates existing object' do
          bulk_insert_item_class.bulk_upsert!([new_object], unique_by: %w[name])

          expect(existing_object.reload.secret_value).to eq('new value')
        end
      end
    end

    context 'when a model with composite primary key is inserted' do
      let_it_be(:bulk_insert_items_with_composite_pk_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'bulk_insert_items_with_composite_pk'

          include BulkInsertSafe
        end
      end

      let(:new_object) { bulk_insert_items_with_composite_pk_class.new(id: 1, name: 'composite') }

      it 'successfully inserts an item' do
        expect(ActiveRecord::InsertAll).to receive(:new)
          .with(
            bulk_insert_items_with_composite_pk_class, [new_object.as_json], on_duplicate: :raise, returning: false, unique_by: %w[id name]
          ).and_call_original

        expect { bulk_insert_items_with_composite_pk_class.bulk_insert!([new_object]) }.to(
          change(bulk_insert_items_with_composite_pk_class, :count).from(0).to(1)
        )
      end
    end
  end
end
