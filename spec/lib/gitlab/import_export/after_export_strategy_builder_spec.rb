require 'spec_helper'

describe Gitlab::ImportExport::AfterExportStrategyBuilder do
  let!(:strategies_namespace) { 'Gitlab::ImportExport::AfterExportStrategies' }

  describe '.build!' do
    context 'when klass param is' do
      it 'null it returns the default strategy' do
        expect(described_class.build!(nil).class).to eq described_class.default_strategy
      end

      it 'not a valid class it raises StrategyNotFoundError exception' do
        expect { described_class.build!('Whatever') }.to raise_error(described_class::StrategyNotFoundError)
      end

      it 'not a descendant of AfterExportStrategy' do
        expect { described_class.build!('User') }.to raise_error(described_class::StrategyNotFoundError)
      end
    end

    it 'initializes strategy with attributes param' do
      params = { param1: 1, param2: 2, param3: 3 }

      strategy = described_class.build!("#{strategies_namespace}::DownloadNotificationStrategy", params)

      params.each { |k, v| expect(strategy.public_send(k)).to eq v }
    end
  end
end
