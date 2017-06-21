require 'spec_helper'

describe BackgroundMigrationWorker do
  describe '.perform' do
    it 'performs a background migration' do
      expect(Gitlab::BackgroundMigration)
        .to receive(:perform)
        .with('Foo', [10, 20])

      described_class.new.perform('Foo', [10, 20])
    end
  end
end
