# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::ImportLabelsWorker, feature_category: :importers do
  include JiraIntegrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, import_type: 'jira') }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    let_it_be(:jira_import, reload: true) { create(:jira_import_state, :scheduled, project: project) }

    context 'when import did not start' do
      it_behaves_like 'cannot do Jira import'
      it_behaves_like 'does not advance to next stage'
    end

    context 'when import started' do
      let!(:jira_integration) { create(:jira_integration, project: project) }

      before do
        stub_jira_integration_test

        jira_import.start!

        WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/label?maxResults=500&startAt=0')
          .to_return(body: {}.to_json)
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
