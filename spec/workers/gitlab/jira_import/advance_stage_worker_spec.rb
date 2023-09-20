# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::AdvanceStageWorker, feature_category: :importers do
  it_behaves_like Gitlab::Import::AdvanceStage, factory: :jira_import_state
end
