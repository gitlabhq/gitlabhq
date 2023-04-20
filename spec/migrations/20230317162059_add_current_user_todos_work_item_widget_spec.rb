# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddCurrentUserTodosWorkItemWidget, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that adds widget to work items definitions', widget_name: 'Current user todos'
end
