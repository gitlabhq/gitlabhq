# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::EachDatabase do
  describe '.each_connection', :add_ci_connection do
    let(:database_base_models) { { main: ActiveRecord::Base, ci: Ci::ApplicationRecord }.with_indifferent_access }

    before do
      allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(database_base_models)
    end

    it 'yields each connection after connecting SharedModel' do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection)
        .with(ActiveRecord::Base.connection).ordered.and_yield

      expect(Gitlab::Database::SharedModel).to receive(:using_connection)
        .with(Ci::ApplicationRecord.connection).ordered.and_yield

      expect { |b| described_class.each_connection(&b) }
        .to yield_successive_args(
          [ActiveRecord::Base.connection, 'main'],
          [Ci::ApplicationRecord.connection, 'ci']
        )
    end

    context 'when only certain databases are selected' do
      it 'yields the selected connections after connecting SharedModel' do
        expect(Gitlab::Database::SharedModel).to receive(:using_connection)
          .with(Ci::ApplicationRecord.connection).ordered.and_yield

        expect { |b| described_class.each_connection(only: 'ci', &b) }
          .to yield_successive_args([Ci::ApplicationRecord.connection, 'ci'])
      end

      context 'when the selected names are passed as symbols' do
        it 'yields the selected connections after connecting SharedModel' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection)
            .with(Ci::ApplicationRecord.connection).ordered.and_yield

          expect { |b| described_class.each_connection(only: :ci, &b) }
            .to yield_successive_args([Ci::ApplicationRecord.connection, 'ci'])
        end
      end

      context 'when the selected names are invalid' do
        it 'does not yield any connections' do
          expect do |b|
            described_class.each_connection(only: :notvalid, &b)
          rescue ArgumentError => e
            expect(e.message).to match(/notvalid is not a valid database name/)
          end.not_to yield_control
        end

        it 'raises an error' do
          expect do
            described_class.each_connection(only: :notvalid) {}
          end.to raise_error(ArgumentError, /notvalid is not a valid database name/)
        end
      end
    end

    context 'when shared connections are not included' do
      def clear_memoization(key)
        Gitlab::Database.remove_instance_variable(key) if Gitlab::Database.instance_variable_defined?(key)
      end

      before do
        allow(Gitlab::Database).to receive(:database_base_models).and_return(database_base_models)

        # Clear the memoization because the return of Gitlab::Database#schemas_to_base_models depends stubbed value
        clear_memoization(:@schemas_to_base_models)
      end

      it 'only yields the unshared connections' do
        # if this is `non-main` connection make it shared with `main`
        allow(Gitlab::Database).to receive(:db_config_share_with) do |db_config|
          db_config.name != 'main' ? 'main' : nil
        end

        expect { |b| described_class.each_connection(include_shared: false, &b) }
          .to yield_successive_args([ActiveRecord::Base.connection, 'main'])
      end
    end
  end

  describe '.each_model_connection' do
    context 'when the model inherits from SharedModel', :add_ci_connection do
      let(:model1) { Class.new(Gitlab::Database::SharedModel) }
      let(:model2) { Class.new(Gitlab::Database::SharedModel) }

      before do
        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared)
          .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord }.with_indifferent_access)
      end

      it 'yields each model with SharedModel connected to each database connection' do
        expect_yielded_models([model1, model2],
          [
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
          expect_yielded_models([model1, model2],
            [
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

        allow(main_model).to receive_message_chain('connection_db_config.name').and_return('main')
        allow(ci_model).to receive_message_chain('connection_db_config.name').and_return('ci')
      end

      it 'yields each model after connecting SharedModel' do
        expect_yielded_models([main_model, ci_model],
          [
            { model: main_model, connection: main_connection, name: 'main' },
            { model: ci_model, connection: ci_connection, name: 'ci' }
          ])
      end
    end

    context 'when the database connections are limited by the only_on option' do
      let(:shared_model) { Class.new(Gitlab::Database::SharedModel) }
      let(:main_model) { Class.new(ActiveRecord::Base) }
      let(:ci_model) { Class.new(Ci::ApplicationRecord) }

      before do
        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared)
          .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord }.with_indifferent_access)

        allow(main_model).to receive_message_chain('connection_db_config.name').and_return('main')
        allow(ci_model).to receive_message_chain('connection_db_config.name').and_return('ci')
      end

      context 'when a single name is passed in' do
        it 'yields models only connected to the given database' do
          expect_yielded_models([main_model, ci_model, shared_model],
            [
              { model: ci_model, connection: Ci::ApplicationRecord.connection, name: 'ci' },
              { model: shared_model, connection: Ci::ApplicationRecord.connection, name: 'ci' }
            ], only_on: 'ci')
        end
      end

      context 'when a list of names are passed in' do
        it 'yields models only connected to the given databases' do
          expect_yielded_models([main_model, ci_model, shared_model],
            [
              { model: main_model, connection: ActiveRecord::Base.connection, name: 'main' },
              { model: ci_model, connection: Ci::ApplicationRecord.connection, name: 'ci' },
              { model: shared_model, connection: ActiveRecord::Base.connection, name: 'main' },
              { model: shared_model, connection: Ci::ApplicationRecord.connection, name: 'ci' }
            ], only_on: %i[main ci])
        end
      end
    end

    def expect_yielded_models(models_to_iterate, expected_values, only_on: nil)
      times_yielded = 0

      described_class.each_model_connection(models_to_iterate, only_on: only_on) do |model, name|
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
