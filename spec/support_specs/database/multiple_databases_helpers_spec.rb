# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database::MultipleDatabasesHelpers' do
  let(:query) do
    <<~SQL
      WITH cte AS MATERIALIZED (SELECT 1) SELECT 1;
    SQL
  end

  it 'preloads database version for ApplicationRecord' do
    counts = ActiveRecord::QueryRecorder
    .new { ApplicationRecord.connection.execute(query) }
    .count

    expect(counts).to eq(1)
  end

  it 'preloads database version for Ci::ApplicationRecord' do
    counts = ActiveRecord::QueryRecorder
    .new { Ci::ApplicationRecord.connection.execute(query) }
    .count

    expect(counts).to eq(1)
  end

  describe '.with_reestablished_active_record_base' do
    context 'when doing establish_connection' do
      context 'on ActiveRecord::Base' do
        it 'raises exception' do
          expect { ActiveRecord::Base.establish_connection(:main) }.to raise_error(/Cannot re-establish/) # rubocop: disable Database/EstablishConnection
        end

        context 'when using with_reestablished_active_record_base' do
          it 'does not raise exception' do
            with_reestablished_active_record_base do
              expect { ActiveRecord::Base.establish_connection(:main) }.not_to raise_error # rubocop: disable Database/EstablishConnection
            end
          end
        end
      end

      context 'on Ci::ApplicationRecord' do
        before do
          skip_if_multiple_databases_not_setup(:ci)
        end

        it 'raises exception' do
          expect { Ci::ApplicationRecord.establish_connection(:ci) }.to raise_error(/Cannot re-establish/) # rubocop: disable Database/EstablishConnection
        end

        context 'when using with_reestablished_active_record_base' do
          it 'does not raise exception' do
            with_reestablished_active_record_base do
              expect { Ci::ApplicationRecord.establish_connection(:main) }.not_to raise_error # rubocop: disable Database/EstablishConnection
            end
          end
        end
      end
    end

    context 'when trying to access connection' do
      context 'when reconnect is true' do
        it 'does not raise exception' do
          with_reestablished_active_record_base(reconnect: true) do
            expect { ApplicationRecord.connection.execute("SELECT 1") }.not_to raise_error
          end
        end
      end

      context 'when reconnect is false' do
        it 'does raise exception' do
          with_reestablished_active_record_base(reconnect: false) do
            expect { ApplicationRecord.connection.execute("SELECT 1") }
              .to raise_error(ActiveRecord::ConnectionNotEstablished)
          end
        end
      end
    end
  end

  describe '.with_added_ci_connection' do
    context 'when only a single database is setup' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it 'connects Ci::ApplicationRecord to the main database for the duration of the block', :aggregate_failures do
        main_database = current_database(ActiveRecord::Base)
        original_database = current_database(Ci::ApplicationRecord)

        with_added_ci_connection do
          expect(current_database(Ci::ApplicationRecord)).to eq(main_database)
        end

        expect(current_database(Ci::ApplicationRecord)).to eq(original_database)
      end
    end

    context 'when multiple databases are setup' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'does not mock the original Ci::ApplicationRecord connection', :aggregate_failures do
        original_database = current_database(Ci::ApplicationRecord)

        with_added_ci_connection do
          expect(current_database(Ci::ApplicationRecord)).to eq(original_database)
        end

        expect(current_database(Ci::ApplicationRecord)).to eq(original_database)
      end
    end

    def current_database(connection_class)
      connection_class.retrieve_connection.execute('select current_database()').first
    end
  end
end
