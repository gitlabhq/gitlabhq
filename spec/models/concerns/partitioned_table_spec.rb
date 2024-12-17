# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PartitionedTable, feature_category: :database do
  subject { my_class.partitioned_by(key, strategy: :monthly) }

  let(:key) { :foo }

  let(:my_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = :p_ci_builds

      include PartitionedTable
    end
  end

  describe '.partitioned_by' do
    context 'with keyword arguments passed to the strategy' do
      subject { my_class.partitioned_by(key, strategy: :monthly, retain_for: 3.months) }

      it 'passes the keyword arguments to the strategy' do
        expect(Gitlab::Database::Partitioning::Time::MonthlyStrategy).to receive(:new).with(my_class, key, retain_for: 3.months).and_call_original

        subject
      end
    end

    it 'assigns the MonthlyStrategy as the partitioning strategy' do
      subject

      expect(my_class.partitioning_strategy).to be_a(Gitlab::Database::Partitioning::Time::MonthlyStrategy)
    end

    it 'passes the partitioning key to the strategy instance' do
      subject

      expect(my_class.partitioning_strategy.partitioning_key).to eq(key)
    end
  end

  describe 'self._returning_columns_for_insert' do
    it 'identifies the columns that are returned on insert' do
      expect(my_class._returning_columns_for_insert).to eq(Array.wrap(my_class.primary_key))
    end

    it 'allows creating a partitionable record' do
      expect { create(:ci_build) }.not_to raise_error
    end
  end
end
