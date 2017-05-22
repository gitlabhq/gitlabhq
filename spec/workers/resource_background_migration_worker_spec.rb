require 'spec_helper'

describe ResourceBackgroundMigrationWorker do
  describe '#perform' do
    let(:resource) { spy('class') }
    let(:migration) { double('migration') }
    let(:records) { [[1, 1234], [2, 2345]] }

    before do
      allow(resource).to receive(:migrations)
        .and_return({ 2222 => migration, 2233 => migration })
    end

    it 'executes migrations for given records' do
      expect(migration).to receive(:perform).with(1, 2222, resource).once
      expect(migration).to receive(:perform).with(1, 2233, resource).once
      expect(migration).to receive(:perform).with(2, 2222, resource).once
      expect(migration).to receive(:perform).with(2, 2233, resource).once

      described_class.new.perform(resource, records)
    end
  end
end
