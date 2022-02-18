# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Instrumentation do
  let(:result_dir) { Dir.mktmpdir }
  let(:connection) { ActiveRecord::Migration.connection }

  after do
    FileUtils.rm_rf(result_dir)
  end
  describe '#observe' do
    subject { described_class.new(result_dir: result_dir) }

    let(:migration_name) { 'test' }
    let(:migration_version) { '12345' }

    it 'executes the given block' do
      expect { |b| subject.observe(version: migration_version, name: migration_name, connection: connection, &b) }.to yield_control
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
      subject { described_class.new(result_dir: result_dir).observe(version: migration_version, name: migration_name, connection: connection) {} }

      it 'records a valid observation', :aggregate_failures do
        expect(subject.walltime).not_to be_nil
        expect(subject.success).to be_truthy
        expect(subject.version).to eq(migration_version)
        expect(subject.name).to eq(migration_name)
      end
    end

    context 'upon failure' do
      where(exception: ['something went wrong', SystemStackError, Interrupt])

      with_them do
        let(:instance) { described_class.new(result_dir: result_dir) }

        subject(:observe) { instance.observe(version: migration_version, name: migration_name, connection: connection) { raise exception } }

        it 'raises the exception' do
          expect { observe }.to raise_error(exception)
        end

        context 'retrieving observations' do
          subject { instance.observations.first }

          before do
            observe
            # rubocop:disable Lint/RescueException
          rescue Exception
            # rubocop:enable Lint/RescueException
            # ignore (we expect this exception)
          end

          it 'records a valid observation', :aggregate_failures do
            expect(subject.walltime).not_to be_nil
            expect(subject.success).to be_falsey
            expect(subject.version).to eq(migration_version)
            expect(subject.name).to eq(migration_name)
          end
        end
      end
    end

    context 'sequence of migrations with failures' do
      subject { described_class.new(result_dir: result_dir) }

      let(:migration1) { double('migration1', call: nil) }
      let(:migration2) { double('migration2', call: nil) }

      it 'records observations for all migrations' do
        subject.observe(version: migration_version, name: migration_name, connection: connection) {}
        subject.observe(version: migration_version, name: migration_name, connection: connection) { raise 'something went wrong' } rescue nil

        expect(subject.observations.size).to eq(2)
      end
    end
  end
end
