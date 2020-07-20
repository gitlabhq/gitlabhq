# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PartitionedTable do
  describe '.partitioned_by' do
    subject { my_class.partitioned_by(key, strategy: :monthly) }

    let(:key) { :foo }

    let(:my_class) do
      Class.new do
        include PartitionedTable
      end
    end

    it 'assigns the MonthlyStrategy as the partitioning strategy' do
      subject

      expect(my_class.partitioning_strategy).to be_a(Gitlab::Database::Partitioning::MonthlyStrategy)
    end

    it 'passes the partitioning key to the strategy instance' do
      subject

      expect(my_class.partitioning_strategy.partitioning_key).to eq(key)
    end

    it 'registers itself with the PartitionCreator' do
      expect(Gitlab::Database::Partitioning::PartitionCreator).to receive(:register).with(my_class)

      subject
    end
  end
end
