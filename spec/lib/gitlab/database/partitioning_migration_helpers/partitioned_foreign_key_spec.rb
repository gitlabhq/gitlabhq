# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::PartitioningMigrationHelpers::PartitionedForeignKey do
  let(:foreign_key) do
    described_class.new(
      to_table: 'issues',
      from_table: 'issue_assignees',
      from_column: 'issue_id',
      to_column: 'id',
      cascade_delete: true)
  end

  describe 'validations' do
    it 'allows keys that reference valid tables and columns' do
      expect(foreign_key).to be_valid
    end

    it 'does not allow keys without a valid to_table' do
      foreign_key.to_table = 'this_is_not_a_real_table'

      expect(foreign_key).not_to be_valid
      expect(foreign_key.errors[:to_table].first).to eq('must be a valid table')
    end

    it 'does not allow keys without a valid from_table' do
      foreign_key.from_table = 'this_is_not_a_real_table'

      expect(foreign_key).not_to be_valid
      expect(foreign_key.errors[:from_table].first).to eq('must be a valid table')
    end

    it 'does not allow keys without a valid to_column' do
      foreign_key.to_column = 'this_is_not_a_real_fk'

      expect(foreign_key).not_to be_valid
      expect(foreign_key.errors[:to_column].first).to eq('must be a valid column')
    end

    it 'does not allow keys without a valid from_column' do
      foreign_key.from_column = 'this_is_not_a_real_pk'

      expect(foreign_key).not_to be_valid
      expect(foreign_key.errors[:from_column].first).to eq('must be a valid column')
    end
  end
end
