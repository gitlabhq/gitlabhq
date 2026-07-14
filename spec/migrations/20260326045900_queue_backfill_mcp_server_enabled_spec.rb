# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMcpServerEnabled, migration: :gitlab_main, feature_category: :mcp_server do
  it 'is a no-op' do
    expect { migrate! }.not_to raise_error
  end

  describe '#down' do
    it 'is a no-op' do
      migrate!
      expect { schema_migrate_down! }.not_to raise_error
    end
  end
end
