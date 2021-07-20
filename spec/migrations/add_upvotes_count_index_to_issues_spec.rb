# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddUpvotesCountIndexToIssues do
  let(:migration_instance) { described_class.new }

  describe '#up' do
    it 'adds index' do
      expect { migrate! }.to change { migration_instance.index_exists?(:issues, [:project_id, :upvotes_count], name: described_class::INDEX_NAME) }.from(false).to(true)
    end
  end

  describe '#down' do
    it 'removes index' do
      migrate!

      expect { schema_migrate_down! }.to change { migration_instance.index_exists?(:issues, [:project_id, :upvotes_count], name: described_class::INDEX_NAME) }.from(true).to(false)
    end
  end
end
