require 'spec_helper'

describe Gitlab::Database::Count::TablesampleCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }
  let(:strategy) { described_class.new(models) }

  subject { strategy.count }

  describe '#count', :postgresql do
    let(:estimates) { { Project => threshold + 1, Identity => threshold - 1 } }
    let(:threshold) { Gitlab::Database::Count::TablesampleCountStrategy::EXACT_COUNT_THRESHOLD }

    before do
      allow(strategy).to receive(:size_estimates).with(check_statistics: false).and_return(estimates)
    end

    context 'for tables with an estimated small size' do
      it 'performs an exact count' do
        expect(Identity).to receive(:count).and_call_original

        expect(subject).to include({ Identity => 1 })
      end
    end

    context 'for tables with an estimated large size' do
      it 'performs a tablesample count' do
        expect(Project).not_to receive(:count)

        result = subject
        expect(result[Project]).to eq(3)
      end
    end

    context 'insufficient permissions' do
      it 'returns an empty hash' do
        allow(strategy).to receive(:size_estimates).and_raise(PG::InsufficientPrivilege)

        expect(subject).to eq({})
      end
    end
  end

  describe '.enabled?' do
    before do
      stub_feature_flags(tablesample_counts: true)
    end

    it 'is enabled for PostgreSQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

      expect(described_class.enabled?).to be_truthy
    end

    it 'is disabled for MySQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

      expect(described_class.enabled?).to be_falsey
    end
  end
end
