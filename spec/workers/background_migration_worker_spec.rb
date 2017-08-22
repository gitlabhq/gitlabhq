require 'spec_helper'

describe BackgroundMigrationWorker, :sidekiq do
  describe '.perform' do
    it 'performs a background migration' do
      expect(Gitlab::BackgroundMigration)
        .to receive(:perform)
        .with('Foo', [10, 20])

      described_class.new.perform('Foo', [10, 20])
    end
  end

  describe '.perform_bulk' do
    it 'enqueues background migrations in bulk' do
      Sidekiq::Testing.fake! do
        described_class.perform_bulk([['Foo', [1]], ['Foo', [2]]])

        expect(described_class.jobs.count).to eq 2
        expect(described_class.jobs).to all(include('enqueued_at'))
      end
    end
  end

  describe '.perform_bulk_in' do
    context 'when delay is valid' do
      it 'correctly schedules background migrations' do
        Sidekiq::Testing.fake! do
          described_class.perform_bulk_in(1.minute, [['Foo', [1]], ['Foo', [2]]])

          expect(described_class.jobs.count).to eq 2
          expect(described_class.jobs).to all(include('at'))
        end
      end
    end

    context 'when delay is invalid' do
      it 'raises an ArgumentError exception' do
        expect { described_class.perform_bulk_in(-60, [['Foo']]) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
