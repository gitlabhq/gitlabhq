# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddDesignsAndDevelopmentWidgetsToTicketWorkItemType, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that adds widgets to a work item type'
end
