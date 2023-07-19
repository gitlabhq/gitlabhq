# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Postgresql::DetachedPartition do
  describe '#ready_to_drop' do
    let_it_be(:drop_before) { described_class.create!(drop_after: 1.day.ago, table_name: 'old_table') }
    let_it_be(:drop_after) { described_class.create!(drop_after: 1.day.from_now, table_name: 'new_table') }

    it 'includes partitions that should be dropped before now' do
      expect(described_class.ready_to_drop.to_a).to include(drop_before)
    end

    it 'does not include partitions that should be dropped after now' do
      expect(described_class.ready_to_drop.to_a).not_to include(drop_after)
    end
  end
end
