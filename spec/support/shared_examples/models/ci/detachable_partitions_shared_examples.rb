# frozen_string_literal: true

RSpec.shared_examples 'a CI model that detaches archived partitions' do
  let(:partitioning_strategy) { described_class.partitioning_strategy }
  let(:partition_class) { partitioning_strategy.initial_partition.class }

  let(:oldest) { build_partition(100) }
  let(:middle) { build_partition(101) }
  let(:newest) { build_partition(102) }
  let(:partitions) { [oldest, middle, newest] }
  let(:archived) { partitions }

  before do
    Ci::Partition.delete_all

    partitions.each do |partition|
      status = archived.include?(partition) ? :archived : :active
      partition_ids = partition.values

      partition_ids.each { |id| create(:ci_partition, status, id: id) }
    end

    allow(partitioning_strategy).to receive(:current_partitions).and_return(partitions)
  end

  subject(:extra_partitions) { partitioning_strategy.extra_partitions }

  def build_partition(value)
    partition_class.new(described_class.table_name, value)
  end

  context 'when every partition is archived' do
    it 'returns all of them but the newest' do
      expect(extra_partitions).to eq([oldest, middle])
    end
  end

  context 'when only the oldest partition is archived' do
    let(:archived) { [oldest] }

    it 'returns the oldest partition' do
      expect(extra_partitions).to eq([oldest])
    end
  end

  context 'when an archived partition follows an active one' do
    let(:archived) { [middle] }

    it 'returns nothing, because detaching stops at the oldest active partition' do
      expect(extra_partitions).to be_empty
    end
  end

  context 'when only the newest partition is archived' do
    let(:archived) { [newest] }

    it { is_expected.to be_empty }
  end

  context 'when ci_detach_archived_partitions is disabled' do
    before do
      stub_feature_flags(ci_detach_archived_partitions: false)
    end

    it { is_expected.to be_empty }
  end
end
