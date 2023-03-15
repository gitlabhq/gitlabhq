# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::ImportAttachmentsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, import_type: 'jira') }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    let_it_be(:jira_import) { create(:jira_import_state, :scheduled, project: project) }

    context 'when import did not start' do
      it_behaves_like 'cannot do Jira import'
      it_behaves_like 'does not advance to next stage'
    end

    context 'when import started' do
      before do
        jira_import.start!
      end

      it_behaves_like 'advance to next stage', :notes
    end
  end
end
