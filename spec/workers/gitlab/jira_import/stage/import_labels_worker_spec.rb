# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::ImportLabelsWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'exit import not started'
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        let!(:import_state) { create(:import_state, project: project) }

        it_behaves_like 'exit import not started'
      end

      context 'when import started' do
        let(:jira_import_data) do
          data = JiraImportData.new
          data << JiraImportData::JiraProjectDetails.new('XX', Time.now.strftime('%Y-%m-%d %H:%M:%S'), { user_id: user.id, name: user.name })
          data
        end
        let(:project) { create(:project, import_data: jira_import_data) }
        let!(:jira_service) { create(:jira_service, project: project) }
        let!(:import_state) { create(:import_state, status: :started, project: project) }

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
