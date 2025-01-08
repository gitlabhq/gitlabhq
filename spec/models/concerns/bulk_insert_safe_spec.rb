# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkInsertSafe, feature_category: :database do
  before_all do
    ActiveRecord::Schema.define do
      create_table :_test_bulk_insert_parent_items, force: true do |t|
        t.string :name, null: false
      end

      create_table :_test_bulk_insert_items, force: true do |t|
        t.string :name, null: true
        t.integer :enum_value, null: false
        t.text :encrypted_secret_value, null: false
        t.string :encrypted_secret_value_iv, null: false
        t.binary :sha_value, null: false, limit: 20
        t.jsonb :jsonb_value, null: false
        t.belongs_to :bulk_insert_parent_item, foreign_key: { to_table: :_test_bulk_insert_parent_items }, null: true
        t.timestamps null: true

        t.index :name, unique: true
      end

      create_table :_test_bulk_insert_items_with_composite_pk, id: false, force: true do |t|
        t.integer :instance_id, null: true
        t.string :name, null: true
      end

      execute("ALTER TABLE _test_bulk_insert_items_with_composite_pk ADD PRIMARY KEY (instance_id,name);")

      create_table :_test_bulk_insert_with_non_serial_pk, id: false, force: true do |t|
        t.integer :project_id, null: false
        t.string :name
      end

      execute("ALTER TABLE _test_bulk_insert_with_non_serial_pk ADD PRIMARY KEY (project_id);")
      execute("ALTER TABLE _test_bulk_insert_with_non_serial_pk
                ADD CONSTRAINT fk_test_bulk_insert_with_non_serial_pk_fk
                FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;")
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :_test_bulk_insert_items, force: true
      drop_table :_test_bulk_insert_parent_items, force: true
      drop_table :_test_bulk_insert_items_with_composite_pk, force: true
      drop_table :_test_bulk_insert_with_non_serial_pk, force: true
    end
  end

  BulkInsertParentItem = Class.new(ActiveRecord::Base) do
    self.table_name = :_test_bulk_insert_parent_items
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
      self.table_name = '_test_bulk_insert_items'

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

      attribute :enum_value, default: 'case_1'
      attribute :sha_value, default: '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
      attribute :jsonb_value, default: -> { { "key" => "value" } }

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
          bulk_insert_item_class.bulk_insert!(all_items, batch_size: 2)
        rescue StandardError
          nil
        end.not_to change { bulk_insert_item_class.count }
      end

      it 'does nothing and returns an empty array when items are empty' do
        expect(bulk_insert_item_class.bulk_insert!([])).to eq([])
        expect(bulk_insert_item_class.count).to eq(0)
      end

      context 'with returns option set' do
        let(:items) { bulk_insert_item_class.valid_list(1) }

        subject(:legacy_bulk_insert) { bulk_insert_item_class.bulk_insert!(items, returns: returns) }

        context 'when is set to :ids' do
          let(:returns) { :ids }

          it { is_expected.to contain_exactly(a_kind_of(Integer)) }
        end

        context 'when is set to nil' do
          let(:returns) { nil }

          it { is_expected.to eq([]) }
        end

        context 'when is set to a list of attributes' do
          let(:returns) { [:id, :sha_value] }

          it { is_expected.to contain_exactly([a_kind_of(Integer), '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12']) }
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
        subject(:bulk_upsert) { bulk_insert_item_class.bulk_upsert!([new_object], unique_by: %w[name]) }

        it 'updates existing object' do
          expect { bulk_upsert }.to change { existing_object.reload.secret_value }.to('new value')
        end

        context 'when the `created_at` attribute is provided' do
          before do
            new_object.created_at = 10.days.from_now
          end

          it 'does not change the existing `created_at` value' do
            expect { bulk_upsert }.not_to change { existing_object.reload.created_at }
          end
        end
      end
    end

    context 'when a model with composite primary key is inserted' do
      let_it_be(:bulk_insert_items_with_composite_pk_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = '_test_bulk_insert_items_with_composite_pk'

          include BulkInsertSafe
        end
      end

      let(:new_object) { bulk_insert_items_with_composite_pk_class.new(instance_id: 1, name: 'composite') }

      it 'successfully inserts an item' do
        expect(ActiveRecord::InsertAll).to receive(:new)
          .with(
            bulk_insert_items_with_composite_pk_class.insert_all_proxy_class,
            [new_object.as_json],
            on_duplicate: :raise, returning: false, unique_by: %w[instance_id name]
          ).and_call_original

        expect { bulk_insert_items_with_composite_pk_class.bulk_insert!([new_object]) }.to(
          change(bulk_insert_items_with_composite_pk_class, :count).from(0).to(1)
        )
      end
    end

    context 'when the primary key is not serial' do
      let_it_be(:project) { create(:project) }
      let_it_be(:bulk_insert_item_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = '_test_bulk_insert_with_non_serial_pk'

          include BulkInsertSafe
        end
      end

      let(:new_object) { bulk_insert_item_class.new(project_id: project.id, name: 'one-to-one') }

      it 'successfully inserts an item' do
        expect { bulk_insert_item_class.bulk_insert!([new_object]) }.to(
          change(bulk_insert_item_class, :count).from(0).to(1)
        )
      end
    end
  end
end
