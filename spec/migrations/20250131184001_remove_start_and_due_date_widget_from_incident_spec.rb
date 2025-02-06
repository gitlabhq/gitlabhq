# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveStartAndDueDateWidgetFromIncident, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that removes widgets from work item types'
end
