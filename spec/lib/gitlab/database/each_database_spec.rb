# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::EachDatabase do
  describe '.each_database_connection' do
    let(:expected_connections) do
      Gitlab::Database.database_base_models.map { |name, model| [model.connection, name] }
    end

    it 'yields each connection after connecting SharedModel' do
      expected_connections.each do |connection, _|
        expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(connection).and_yield
      end

      yielded_connections = []

      described_class.each_database_connection do |connection, name|
        yielded_connections << [connection, name]
      end

      expect(yielded_connections).to match_array(expected_connections)
    end
  end

  describe '.each_model_connection' do
    let(:model1) { double(connection: double, table_name: 'table1') }
    let(:model2) { double(connection: double, table_name: 'table2') }

    before do
      allow(model1.connection).to receive_message_chain('pool.db_config.name').and_return('name1')
      allow(model2.connection).to receive_message_chain('pool.db_config.name').and_return('name2')
    end

    it 'yields each model after connecting SharedModel' do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(model1.connection).and_yield
      expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(model2.connection).and_yield

      yielded_models = []

      described_class.each_model_connection([model1, model2]) do |model, name|
        yielded_models << [model, name]
      end

      expect(yielded_models).to match_array([[model1, 'name1'], [model2, 'name2']])
    end
  end
end
