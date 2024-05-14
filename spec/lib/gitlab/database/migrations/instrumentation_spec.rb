# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Instrumentation do
  subject(:instrumentation) { described_class.new(result_dir: result_dir) }

  let(:result_dir) { Dir.mktmpdir }
  let(:connection) { ActiveRecord::Migration.connection }

  after do
    FileUtils.rm_rf(result_dir)
  end

  describe '#observe' do
    def load_observation(result_dir, migration_name)
      Gitlab::Json.parse(File.read(File.join(result_dir, migration_name, described_class::STATS_FILENAME)))
    end

    let(:migration_name) { 'test' }
    let(:migration_version) { '12345' }
    let(:migration_meta) { { 'max_batch_size' => 1, 'total_tuple_count' => 10, 'interval' => 60 } }
    let(:expected_json_keys) do
      %w[version name walltime success total_database_size_change query_statistics error_message]
    end

    it 'executes the given block' do
      expect do |b|
        instrumentation.observe(version: migration_version, name: migration_name, connection: connection, meta: migration_meta, &b)
      end.to yield_control
    end

    context 'behavior with observers' do
      subject { described_class.new(observer_classes: [Gitlab::Database::Migrations::Observers::MigrationObserver], result_dir: result_dir).observe(version: migration_version, name: migration_name, connection: connection) {} }

      let(:observer) { instance_double('Gitlab::Database::Migrations::Observers::MigrationObserver', before: nil, after: nil, record: nil) }

      before do
        allow(Gitlab::Database::Migrations::Observers::MigrationObserver).to receive(:new).and_return(observer)
      end

      it 'instantiates observer with observation' do
        expect(Gitlab::Database::Migrations::Observers::MigrationObserver)
          .to receive(:new)
          .with(instance_of(Gitlab::Database::Migrations::Observation), anything, connection) { |observation| expect(observation.version).to eq(migration_version) }
          .and_return(observer)

        subject
      end

      it 'calls #before, #after, #record on given observers' do
        expect(observer).to receive(:before).ordered
        expect(observer).to receive(:after).ordered
        expect(observer).to receive(:record).ordered

        subject
      end

      it 'ignores errors coming from observers #before' do
        expect(observer).to receive(:before).and_raise('some error')

        subject
      end

      it 'ignores errors coming from observers #after' do
        expect(observer).to receive(:after).and_raise('some error')

        subject
      end

      it 'ignores errors coming from observers #record' do
        expect(observer).to receive(:record).and_raise('some error')

        subject
      end
    end

    context 'on successful execution' do
      subject do
        instrumentation.observe(
          version: migration_version,
          name: migration_name,
          connection: connection,
          meta: migration_meta
        ) {}
      end

      it 'records a valid observation', :aggregate_failures do
        expect(subject.walltime).not_to be_nil
        expect(subject.success).to be_truthy
        expect(subject.version).to eq(migration_version)
        expect(subject.name).to eq(migration_name)
      end

      it 'transforms observation to expected json' do
        expect(Gitlab::Json.parse(subject.to_json).keys).to contain_exactly(*expected_json_keys)
      end
    end

    context 'upon failure' do
      where(:exception, :error_message) do
        [[StandardError, 'something went wrong'], [ActiveRecord::StatementTimeout, 'timeout']]
      end

      with_them do
        subject(:observe) do
          instrumentation.observe(
            version: migration_version,
            name: migration_name,
            connection: connection,
            meta: migration_meta
          ) { raise exception, error_message }
        end

        context 'retrieving observations' do
          subject { load_observation(result_dir, migration_name) }

          before do
            observe
          rescue Exception # rubocop:disable Lint/RescueException
            # ignore (we expect this exception)
          end

          it 'records a valid observation', :aggregate_failures do
            expect(subject['walltime']).not_to be_nil
            expect(subject['success']).to be_falsey
            expect(subject['version']).to eq(migration_version)
            expect(subject['name']).to eq(migration_name)
            expect(subject['error_message']).to eq(error_message)
          end

          it 'transforms observation to expected json' do
            expect(Gitlab::Json.parse(subject.to_json).keys).to contain_exactly(*expected_json_keys)
          end
        end
      end
    end

    context 'sequence of migrations with failures' do
      let(:migration1) { double('migration1', call: nil) }
      let(:migration2) { double('migration2', call: nil) }

      let(:migration_name_2) { 'other_migration' }
      let(:migration_version_2) { '98765' }

      it 'records observations for all migrations' do
        instrumentation.observe(version: migration_version, name: migration_name, connection: connection) {}
        begin
          instrumentation.observe(version: migration_version_2, name: migration_name_2, connection: connection) { raise 'something went wrong' }
        rescue StandardError
          nil
        end

        expect { load_observation(result_dir, migration_name) }.not_to raise_error
        expect { load_observation(result_dir, migration_name_2) }.not_to raise_error

        # Each observation is a subdirectory of the result_dir, so here we check that we didn't record an extra one
        expect(Pathname(result_dir).children.map { |d| d.basename.to_s }).to contain_exactly(migration_name, migration_name_2)
      end
    end
  end
end
