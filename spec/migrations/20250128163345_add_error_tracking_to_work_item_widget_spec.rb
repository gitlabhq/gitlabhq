# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddErrorTrackingToWorkItemWidget, :migration, feature_category: :team_planning do
  # Tests for `n` widgets in your migration when using the work items widgets migration helper
  it_behaves_like 'migration that adds widgets to a work item type'
end
