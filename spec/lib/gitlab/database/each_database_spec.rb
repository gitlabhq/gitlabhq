# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::EachDatabase do
  describe '.each_database_connection' do
    before do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord }.with_indifferent_access)
    end

    it 'yields each connection after connecting SharedModel', :add_ci_connection do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection)
        .with(ActiveRecord::Base.connection).ordered.and_yield

      expect(Gitlab::Database::SharedModel).to receive(:using_connection)
        .with(Ci::ApplicationRecord.connection).ordered.and_yield

      expect { |b| described_class.each_database_connection(&b) }
        .to yield_successive_args(
          [ActiveRecord::Base.connection, 'main'],
          [Ci::ApplicationRecord.connection, 'ci']
        )
    end
  end

  describe '.each_model_connection' do
    context 'when the model inherits from SharedModel', :add_ci_connection do
      let(:model1) { Class.new(Gitlab::Database::SharedModel) }
      let(:model2) { Class.new(Gitlab::Database::SharedModel) }

      before do
        allow(Gitlab::Database).to receive(:database_base_models)
          .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord }.with_indifferent_access)
      end

      it 'yields each model with SharedModel connected to each database connection' do
        expect_yielded_models([model1, model2], [
          { model: model1, connection: ActiveRecord::Base.connection, name: 'main' },
          { model: model1, connection: Ci::ApplicationRecord.connection, name: 'ci' },
          { model: model2, connection: ActiveRecord::Base.connection, name: 'main' },
          { model: model2, connection: Ci::ApplicationRecord.connection, name: 'ci' }
        ])
      end

      context 'when the model limits connection names' do
        before do
          model1.limit_connection_names = %i[main]
          model2.limit_connection_names = %i[ci]
        end

        it 'only yields the model with SharedModel connected to the limited connections' do
          expect_yielded_models([model1, model2], [
            { model: model1, connection: ActiveRecord::Base.connection, name: 'main' },
            { model: model2, connection: Ci::ApplicationRecord.connection, name: 'ci' }
          ])
        end
      end
    end

    context 'when the model does not inherit from SharedModel' do
      let(:main_model) { Class.new(ActiveRecord::Base) }
      let(:ci_model) { Class.new(Ci::ApplicationRecord) }

      let(:main_connection) { double(:connection) }
      let(:ci_connection) { double(:connection) }

      before do
        allow(main_model).to receive(:connection).and_return(main_connection)
        allow(ci_model).to receive(:connection).and_return(ci_connection)

        allow(main_connection).to receive_message_chain('pool.db_config.name').and_return('main')
        allow(ci_connection).to receive_message_chain('pool.db_config.name').and_return('ci')
      end

      it 'yields each model after connecting SharedModel' do
        expect_yielded_models([main_model, ci_model], [
          { model: main_model, connection: main_connection, name: 'main' },
          { model: ci_model, connection: ci_connection, name: 'ci' }
        ])
      end
    end

    def expect_yielded_models(models_to_iterate, expected_values)
      times_yielded = 0

      described_class.each_model_connection(models_to_iterate) do |model, name|
        expected = expected_values[times_yielded]

        expect(model).to be(expected[:model])
        expect(model.connection).to be(expected[:connection])
        expect(name).to eq(expected[:name])

        times_yielded += 1
      end

      expect(times_yielded).to eq(expected_values.size)
    end
  end
end
