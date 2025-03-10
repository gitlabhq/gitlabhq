# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddVulnerabilitiesWidgetToWorkItemTypes, :migration, feature_category: :vulnerability_management do
  it_behaves_like 'migration that adds widgets to a work item type'
end
