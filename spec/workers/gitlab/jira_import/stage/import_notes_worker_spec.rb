# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::ImportNotesWorker do
  let_it_be(:project) { create(:project, import_type: 'jira') }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag disabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'cannot do Jira import'
      it_behaves_like 'does not advance to next stage'
    end

    context 'when feature flag enabled' do
      let_it_be(:jira_import) { create(:jira_import_state, :scheduled, project: project) }

      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        it_behaves_like 'cannot do Jira import'
        it_behaves_like 'does not advance to next stage'
      end

      context 'when import started' do
        before do
          jira_import.start!
        end

        it_behaves_like 'advance to next stage', :finish
      end
    end
  end
end
