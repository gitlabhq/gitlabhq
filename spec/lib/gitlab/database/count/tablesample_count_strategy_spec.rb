require 'spec_helper'

describe Gitlab::Database::Count::TablesampleCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
    create(:group)
  end

  let(:models) { [Project, Identity, Group, Namespace] }
  let(:strategy) { described_class.new(models) }

  subject { strategy.count }

  describe '#count' do
    let(:estimates) do
      {
        Project => threshold + 1,
        Identity => threshold - 1,
        Group => threshold + 1,
        Namespace => threshold + 1
      }
    end
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
        expect(Group).not_to receive(:count)
        expect(Namespace).not_to receive(:count)

        result = subject
        expect(result[Project]).to eq(3)
        expect(result[Group]).to eq(1)
        expect(result[Namespace]).to eq(4)
      end
    end

    context 'insufficient permissions' do
      it 'returns an empty hash' do
        allow(strategy).to receive(:size_estimates).and_raise(PG::InsufficientPrivilege)

        expect(subject).to eq({})
      end
    end
  end
end
