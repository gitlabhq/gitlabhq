# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database do
  before do
    stub_const('MigrationTest', Class.new { include Gitlab::Database })
  end

  describe 'EXTRA_SCHEMAS' do
    it 'contains only schemas starting with gitlab_ prefix' do
      described_class::EXTRA_SCHEMAS.each do |schema|
        expect(schema.to_s).to start_with('gitlab_')
      end
    end
  end

  describe '.has_config?' do
    context 'two tier database config' do
      before do
        allow(Gitlab::Application).to receive_message_chain(:config, :database_configuration, :[]).with(Rails.env)
          .and_return({ "adapter" => "postgresql", "database" => "gitlabhq_test" })
      end

      it 'returns false for primary' do
        expect(described_class.has_config?(:primary)).to eq(false)
      end

      it 'returns false for ci' do
        expect(described_class.has_config?(:ci)).to eq(false)
      end
    end

    context 'three tier database config' do
      before do
        allow(Gitlab::Application).to receive_message_chain(:config, :database_configuration, :[]).with(Rails.env)
          .and_return({
            "primary" => { "adapter" => "postgresql", "database" => "gitlabhq_test" },
            "ci" => { "adapter" => "postgresql", "database" => "gitlabhq_test_ci" }
          })
      end

      it 'returns true for primary' do
        expect(described_class.has_config?(:primary)).to eq(true)
      end

      it 'returns true for ci' do
        expect(described_class.has_config?(:ci)).to eq(true)
      end

      it 'returns false for non-existent' do
        expect(described_class.has_config?(:nonexistent)).to eq(false)
      end
    end
  end

  describe '.main_database?' do
    using RSpec::Parameterized::TableSyntax

    where(:database_name, :result) do
      :main     | true
      'main'    | true
      :ci       | false
      'ci'      | false
      :archive  | false
      'archive' | false
    end

    with_them do
      it { expect(described_class.main_database?(database_name)).to eq(result) }
    end
  end

  describe '.ci_database?' do
    using RSpec::Parameterized::TableSyntax

    where(:database_name, :result) do
      :main     | false
      'main'    | false
      :ci       | true
      'ci'      | true
      :archive  | false
      'archive' | false
    end

    with_them do
      it { expect(described_class.ci_database?(database_name)).to eq(result) }
    end
  end

  describe '.check_postgres_version_and_print_warning' do
    subject { described_class.check_postgres_version_and_print_warning }

    it 'prints a warning if not compliant with minimum postgres version' do
      allow(described_class.main).to receive(:postgresql_minimum_supported_version?).and_return(false)

      expect(Kernel).to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'doesnt print a warning if compliant with minimum postgres version' do
      allow(described_class.main).to receive(:postgresql_minimum_supported_version?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'doesnt print a warning in Rails runner environment' do
      allow(described_class.main).to receive(:postgresql_minimum_supported_version?).and_return(false)
      allow(Gitlab::Runtime).to receive(:rails_runner?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'ignores ActiveRecord errors' do
      allow(described_class.main).to receive(:postgresql_minimum_supported_version?).and_raise(ActiveRecord::ActiveRecordError)

      expect { subject }.not_to raise_error
    end

    it 'ignores Postgres errors' do
      allow(described_class.main).to receive(:postgresql_minimum_supported_version?).and_raise(PG::Error)

      expect { subject }.not_to raise_error
    end
  end

  describe '.nulls_last_order' do
    it { expect(described_class.nulls_last_order('column', 'ASC')).to eq 'column ASC NULLS LAST'}
    it { expect(described_class.nulls_last_order('column', 'DESC')).to eq 'column DESC NULLS LAST'}
  end

  describe '.nulls_first_order' do
    it { expect(described_class.nulls_first_order('column', 'ASC')).to eq 'column ASC NULLS FIRST'}
    it { expect(described_class.nulls_first_order('column', 'DESC')).to eq 'column DESC NULLS FIRST'}
  end

  describe '.db_config_name' do
    it 'returns the db_config name for the connection' do
      connection = ActiveRecord::Base.connection

      expect(described_class.db_config_name(connection)).to be_a(String)
      expect(described_class.db_config_name(connection)).to eq(connection.pool.db_config.name)
    end

    context 'when the pool is a NullPool' do
      it 'returns unknown' do
        connection = double(:active_record_connection, pool: ActiveRecord::ConnectionAdapters::NullPool.new)

        expect(described_class.db_config_name(connection)).to eq('unknown')
      end
    end
  end

  describe '#true_value' do
    it 'returns correct value' do
      expect(described_class.true_value).to eq "'t'"
    end
  end

  describe '#false_value' do
    it 'returns correct value' do
      expect(described_class.false_value).to eq "'f'"
    end
  end

  describe '#sanitize_timestamp' do
    let(:max_timestamp) { Time.at((1 << 31) - 1) }

    subject { described_class.sanitize_timestamp(timestamp) }

    context 'with a timestamp smaller than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp - 10.years }

      it 'returns the given timestamp' do
        expect(subject).to eq(timestamp)
      end
    end

    context 'with a timestamp larger than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp + 1.second }

      it 'returns MAX_TIMESTAMP_VALUE' do
        expect(subject).to eq(max_timestamp)
      end
    end
  end

  describe '.read_only?' do
    it 'returns false' do
      expect(described_class.read_only?).to eq(false)
    end
  end

  describe '.read_write' do
    it 'returns true' do
      expect(described_class.read_write?).to eq(true)
    end
  end

  describe 'ActiveRecordBaseTransactionMetrics' do
    def subscribe_events
      events = []

      begin
        subscriber = ActiveSupport::Notifications.subscribe('transaction.active_record') do |e|
          events << e
        end

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      events
    end

    context 'without a transaction block' do
      it 'does not publish a transaction event' do
        events = subscribe_events do
          User.first
        end

        expect(events).to be_empty
      end
    end

    context 'within a transaction block' do
      it 'publishes a transaction event' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            User.first
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end

    context 'within an empty transaction block' do
      it 'publishes a transaction event' do
        events = subscribe_events do
          ActiveRecord::Base.transaction {}
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end

    context 'within a nested transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.transaction do
              ActiveRecord::Base.transaction do
                User.first
              end
            end
          end
        end

        expect(events.length).to be(3)

        events.each do |event|
          expect(event).not_to be_nil
          expect(event.duration).to be > 0.0
          expect(event.payload).to a_hash_including(
            connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
          )
        end
      end
    end

    context 'within a cancelled transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ActiveRecord::Base.transaction do
            User.first
            raise ActiveRecord::Rollback
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
        expect(event.payload).to a_hash_including(
          connection: be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
        )
      end
    end
  end
end
