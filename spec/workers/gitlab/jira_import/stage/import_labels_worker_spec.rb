# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::ImportLabelsWorker do
  let_it_be(:user) { create(:user) }
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
      let_it_be(:jira_import, reload: true) { create(:jira_import_state, :scheduled, project: project) }

      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        it_behaves_like 'cannot do Jira import'
        it_behaves_like 'does not advance to next stage'
      end

      context 'when import started' do
        let!(:jira_service) { create(:jira_service, project: project) }

        before do
          jira_import.start!
        end

        it_behaves_like 'advance to next stage', :issues

        it 'executes labels importer' do
          expect_next_instance_of(Gitlab::JiraImport::LabelsImporter) do |instance|
            expect(instance).to receive(:execute).and_return(Gitlab::JobWaiter.new)
          end

          described_class.new.perform(project.id)
        end
      end
    end
  end
end
