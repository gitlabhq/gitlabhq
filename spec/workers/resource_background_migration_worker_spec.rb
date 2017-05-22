require 'spec_helper'

describe ResourceBackgroundMigrationWorker do
  describe '#perform' do
    let(:resource_class) { double('class') }
    let(:migration) { double('migration') }
    let(:records) { [[1, 1234], [2, 2345]] }

    before do
      allow(resource_class).to receive(:migrations)
        .and_return([migration, migration])
    end

    it 'executes migrations for given records' do
      expect(migration).to receive(:perform).with(1).twice
      expect(migration).to receive(:perform).with(2).twice

      subject.perform(resource_class, records)
    end
  end
end
