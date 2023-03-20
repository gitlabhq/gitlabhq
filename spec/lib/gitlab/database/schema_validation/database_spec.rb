# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Database, feature_category: :database do
  subject(:database) { described_class.new(connection) }

  let(:database_model) { Gitlab::Database.database_base_models['main'] }
  let(:connection) { database_model.connection }

  context 'when having indexes' do
    let(:schema_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index }
    let(:results) do
      [['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']]
    end

    before do
      allow(connection).to receive(:select_rows).and_return(results)
    end

    describe '#fetch_index_by_name' do
      context 'when index does not exist' do
        it 'returns nil' do
          index = database.fetch_index_by_name('non_existing_index')

          expect(index).to be_nil
        end
      end

      it 'returns index by name' do
        index = database.fetch_index_by_name('index')

        expect(index.name).to eq('index')
      end
    end

    describe '#index_exists?' do
      context 'when index exists' do
        it 'returns true' do
          index_exists = database.index_exists?('index')

          expect(index_exists).to be_truthy
        end
      end

      context 'when index does not exist' do
        it 'returns false' do
          index_exists = database.index_exists?('non_existing_index')

          expect(index_exists).to be_falsey
        end
      end
    end

    describe '#indexes' do
      it 'returns indexes' do
        indexes = database.indexes

        expect(indexes).to all(be_a(schema_object))
        expect(indexes.map(&:name)).to eq(['index'])
      end
    end
  end

  context 'when having triggers' do
    let(:schema_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Trigger }
    let(:results) do
      { 'my_trigger' => 'CREATE TRIGGER my_trigger BEFORE INSERT ON todos FOR EACH ROW EXECUTE FUNCTION trigger()' }
    end

    before do
      allow(database).to receive(:fetch_triggers).and_return(results)
    end

    describe '#fetch_trigger_by_name' do
      context 'when trigger does not exist' do
        it 'returns nil' do
          expect(database.fetch_trigger_by_name('non_existing_trigger')).to be_nil
        end
      end

      it 'returns trigger by name' do
        expect(database.fetch_trigger_by_name('my_trigger').name).to eq('my_trigger')
      end
    end

    describe '#trigger_exists?' do
      context 'when trigger exists' do
        it 'returns true' do
          expect(database.trigger_exists?('my_trigger')).to be_truthy
        end
      end

      context 'when trigger does not exist' do
        it 'returns false' do
          expect(database.trigger_exists?('non_existing_trigger')).to be_falsey
        end
      end
    end

    describe '#triggers' do
      it 'returns triggers' do
        triggers = database.triggers

        expect(triggers).to all(be_a(schema_object))
        expect(triggers.map(&:name)).to eq(['my_trigger'])
      end
    end
  end
end
