require 'spec_helper'

describe Gitlab::BackgroundMigration do
  describe '.queue' do
    it 'returns background migration worker queue' do
      expect(described_class.queue)
        .to eq BackgroundMigrationWorker.sidekiq_options['queue']
    end
  end

  describe '.steal' do
    context 'when there are enqueued jobs present' do
      let(:queue) { [double(:job, args: ['Foo', [10, 20]])] }

      before do
        allow(Sidekiq::Queue).to receive(:new)
          .with(described_class.queue)
          .and_return(queue)
      end

      it 'steals jobs from a queue' do
        expect(queue[0]).to receive(:delete)

        expect(described_class).to receive(:perform).with('Foo', [10, 20])

        described_class.steal('Foo')
      end

      it 'does not steal jobs for a different migration' do
        expect(described_class).not_to receive(:perform)

        expect(queue[0]).not_to receive(:delete)

        described_class.steal('Bar')
      end
    end
  end

  describe '.perform' do
    it 'performs a background migration' do
      instance = double(:instance)
      klass = double(:klass, new: instance)

      expect(described_class).to receive(:const_get)
        .with('Foo')
        .and_return(klass)

      expect(instance).to receive(:perform).with(10, 20)

      described_class.perform('Foo', [10, 20])
    end
  end
end
