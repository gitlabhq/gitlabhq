# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DynamicModelHelpers, feature_category: :database do
  let(:including_class) { Class.new.include(described_class) }
  let(:table_name) { Project.table_name }
  let(:connection) { Project.connection }

  describe '#define_batchable_model' do
    subject(:model) { including_class.new.define_batchable_model(table_name, connection: connection) }

    it 'is an ActiveRecord model' do
      expect(model.ancestors).to include(ActiveRecord::Base)
    end

    it 'includes EachBatch' do
      expect(model.included_modules).to include(EachBatch)
    end

    it 'has the correct table name' do
      expect(model.table_name).to eq(table_name)
    end

    it 'has the inheritance type column disable' do
      expect(model.inheritance_column).to eq('_type_disabled')
    end

    context 'for primary key' do
      subject(:model) do
        including_class.new.define_batchable_model(table_name, connection: connection, primary_key: primary_key)
      end

      context 'when table primary key is a single column' do
        let(:primary_key) { nil }

        context 'when primary key is nil' do
          it 'does not change the primary key from :id' do
            expect(model.primary_key).to eq('id')
          end
        end

        context 'when primary key is not nil' do
          let(:primary_key) { 'other_column' }

          it 'does not change the primary key from :id' do
            expect(model.primary_key).to eq('id')
          end
        end
      end

      context 'when table has composite primary key' do
        let(:primary_key) { nil }
        let(:table_name) { :_test_composite_primary_key }

        before do
          connection.execute(<<~SQL)
            DROP TABLE IF EXISTS #{table_name};

            CREATE TABLE #{table_name} (
              id integer NOT NULL,
              partition_id integer NOT NULL,
              PRIMARY KEY (id, partition_id)
            );
          SQL
        end

        context 'when primary key is nil' do
          it 'does not change the primary key from nil' do
            expect(model.primary_key).to be_nil
          end
        end

        context 'when primary key is not nil' do
          let(:primary_key) { 'id' }

          it 'changes the primary key' do
            expect(model.primary_key).to eq('id')
          end
        end
      end
    end
  end

  describe '#each_batch' do
    subject { including_class.new }

    before do
      create_list(:project, 2)
    end

    context 'when no transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(false)
      end

      it 'iterates table in batches' do
        each_batch_size = ->(&block) do
          subject.each_batch(table_name, connection: connection, of: 1) do |batch|
            block.call(batch.size)
          end
        end

        expect { |b| each_batch_size.call(&b) }
          .to yield_successive_args(1, 1)
      end

      context 'when a column to be batched over is specified' do
        let(:projects) { Project.order(project_namespace_id: :asc) }

        it 'iterates table in batches using the given column' do
          each_batch_ids = ->(&block) do
            subject.each_batch(table_name, connection: connection, of: 1, column: :project_namespace_id) do |batch|
              block.call(batch.pluck(:project_namespace_id))
            end
          end

          expect { |b| each_batch_ids.call(&b) }
            .to yield_successive_args([projects.first.project_namespace_id], [projects.last.project_namespace_id])
        end
      end
    end

    context 'when transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.each_batch(table_name, connection: connection, of: 1) { |batch| batch.size } }
          .to raise_error(RuntimeError, /each_batch should not run inside a transaction/)
      end
    end
  end

  describe '#each_batch_range' do
    subject { including_class.new }

    let(:first_project) { create(:project) }
    let(:second_project) { create(:project) }

    context 'when no transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(false)
      end

      it 'iterates table in batch ranges' do
        expect { |b| subject.each_batch_range(table_name, connection: connection, of: 1, &b) }
          .to yield_successive_args(
            [first_project.id, first_project.id],
            [second_project.id, second_project.id]
          )
      end

      it 'yields only one batch if bigger than the table size' do
        expect { |b| subject.each_batch_range(table_name, connection: connection, of: 2, &b) }
          .to yield_successive_args([first_project.id, second_project.id])
      end

      it 'makes it possible to apply a scope' do
        each_batch_limited = ->(&b) do
          subject.each_batch_range(table_name, connection: connection, scope: ->(table) { table.limit(1) }, of: 1, &b)
        end

        expect { |b| each_batch_limited.call(&b) }
          .to yield_successive_args([first_project.id, first_project.id])
      end

      context 'when primary key is not named id' do
        let(:namespace_settings1) { create(:namespace_settings) }
        let(:namespace_settings2) { create(:namespace_settings) }
        let(:table_name) { NamespaceSetting.table_name }
        let(:connection) { NamespaceSetting.connection }
        let(:primary_key) { subject.define_batchable_model(table_name, connection: connection).primary_key }

        it 'iterates table in batch ranges using the correct primary key' do
          expect(primary_key).to eq("namespace_id") # Sanity check the primary key is not id
          expect { |b| subject.each_batch_range(table_name, connection: connection, of: 1, &b) }
            .to yield_successive_args(
              [namespace_settings1.namespace_id, namespace_settings1.namespace_id],
              [namespace_settings2.namespace_id, namespace_settings2.namespace_id]
            )
        end
      end

      context 'when a column to be batched over is specified' do
        it 'iterates table in batch ranges using the given column' do
          expect do |b|
            subject.each_batch_range(table_name, connection: connection, of: 1, column: :project_namespace_id, &b)
          end
            .to yield_successive_args(
              [first_project.project_namespace_id, first_project.project_namespace_id],
              [second_project.project_namespace_id, second_project.project_namespace_id]
            )
        end
      end
    end

    context 'when transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.each_batch_range(table_name, connection: connection, of: 1) { 1 } }
          .to raise_error(RuntimeError, /each_batch should not run inside a transaction/)
      end
    end
  end
end
