# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveMetricsUsersStarredDashboards, feature_category: :observability do
  include Database::TableSchemaHelpers

  it 'does nothing' do
    expect { migrate! }.not_to raise_error
    expect { schema_migrate_down! }.not_to raise_error
  end
end
