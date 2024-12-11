# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddDevWidgetToTasks, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that adds widgets to a work item type' do
    let(:target_type_enum_value) { described_class::TASK_ENUM_VALUE }
  end
end
