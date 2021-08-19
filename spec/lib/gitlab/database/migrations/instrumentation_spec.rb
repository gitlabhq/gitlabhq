# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Instrumentation do
  describe '#observe' do
    subject { described_class.new }

    let(:migration_name) { 'test' }
    let(:migration_version) { '12345' }

    it 'executes the given block' do
      expect { |b| subject.observe(version: migration_version, name: migration_name, &b) }.to yield_control
    end

    context 'behavior with observers' do
      subject { described_class.new([Gitlab::Database::Migrations::Observers::MigrationObserver]).observe(version: migration_version, name: migration_name) {} }

      let(:observer) { instance_double('Gitlab::Database::Migrations::Observers::MigrationObserver', before: nil, after: nil, record: nil) }

      before do
        allow(Gitlab::Database::Migrations::Observers::MigrationObserver).to receive(:new).and_return(observer)
      end

      it 'instantiates observer with observation' do
        expect(Gitlab::Database::Migrations::Observers::MigrationObserver)
          .to receive(:new)
          .with(instance_of(Gitlab::Database::Migrations::Observation)) { |observation| expect(observation.version).to eq(migration_version) }
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
      subject { described_class.new.observe(version: migration_version, name: migration_name) {} }

      it 'records walltime' do
        expect(subject.walltime).not_to be_nil
      end

      it 'records success' do
        expect(subject.success).to be_truthy
      end

      it 'records the migration version' do
        expect(subject.version).to eq(migration_version)
      end

      it 'records the migration name' do
        expect(subject.name).to eq(migration_name)
      end
    end

    context 'upon failure' do
      subject { described_class.new.observe(version: migration_version, name: migration_name) { raise 'something went wrong' } }

      it 'raises the exception' do
        expect { subject }.to raise_error(/something went wrong/)
      end

      context 'retrieving observations' do
        subject { instance.observations.first }

        before do
          instance.observe(version: migration_version, name: migration_name) { raise 'something went wrong' }
        rescue StandardError
          # ignore
        end

        let(:instance) { described_class.new }

        it 'records walltime' do
          expect(subject.walltime).not_to be_nil
        end

        it 'records failure' do
          expect(subject.success).to be_falsey
        end

        it 'records the migration version' do
          expect(subject.version).to eq(migration_version)
        end

        it 'records the migration name' do
          expect(subject.name).to eq(migration_name)
        end
      end
    end

    context 'sequence of migrations with failures' do
      subject { described_class.new }

      let(:migration1) { double('migration1', call: nil) }
      let(:migration2) { double('migration2', call: nil) }

      it 'records observations for all migrations' do
        subject.observe(version: migration_version, name: migration_name) {}
        subject.observe(version: migration_version, name: migration_name) { raise 'something went wrong' } rescue nil

        expect(subject.observations.size).to eq(2)
      end
    end
  end
end
