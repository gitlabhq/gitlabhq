# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::LabelsImporter do
  include JiraServiceHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project) }

  let(:importer) { described_class.new(project) }

  subject { importer.execute }

  before do
    stub_const('Gitlab::JiraImport::LabelsImporter::MAX_LABELS', 2)
  end

  describe '#execute', :clean_gitlab_redis_cache do
    before do
      stub_jira_integration_test
    end

    context 'when label is missing from jira import' do
      let_it_be(:no_label_jira_import) { create(:jira_import_state, label: nil, project: project) }

      it 'raises error' do
        expect { subject }.to raise_error(Projects::ImportService::Error, 'Failed to find import label for Jira import.')
      end
    end

    context 'when jira import label exists' do
      let_it_be(:label)                  { create(:label) }
      let_it_be(:jira_import_with_label) { create(:jira_import_state, label: label, project: project) }
      let_it_be(:issue_label)            { create(:label, project: project, title: 'bug') }

      let(:jira_labels_1) { { "maxResults" => 2, "startAt" => 0, "total" => 3, "isLast" => false, "values" => %w(backend bug) } }
      let(:jira_labels_2) { { "maxResults" => 2, "startAt" => 2, "total" => 3, "isLast" => true, "values" => %w(feature) } }

      context 'when labels are returned from jira' do
        before do
          client = double
          expect(importer).to receive(:client).twice.and_return(client)
          allow(client).to receive(:get).twice.and_return(jira_labels_1, jira_labels_2)
        end

        it 'caches import label' do
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.import_label_cache_key(project.id))).to be nil

          subject

          expect(Gitlab::JiraImport.get_import_label_id(project.id).to_i).to eq(label.id)
        end

        it 'calls Gitlab::JiraImport::HandleLabelsService' do
          expect(Gitlab::JiraImport::HandleLabelsService).to receive(:new).with(project, %w(backend bug)).and_return(double(execute: [1, 2]))
          expect(Gitlab::JiraImport::HandleLabelsService).to receive(:new).with(project, %w(feature)).and_return(double(execute: [3]))

          subject
        end
      end

      context 'when there are no labels to be handled' do
        shared_examples 'no labels handling' do
          it 'does not call Gitlab::JiraImport::HandleLabelsService' do
            expect(Gitlab::JiraImport::HandleLabelsService).not_to receive(:new)

            subject
          end
        end

        let(:jira_labels) { { "maxResults" => 2, "startAt" => 0, "total" => 3, "values" => [] } }

        before do
          client = double
          expect(importer).to receive(:client).and_return(client)
          allow(client).to receive(:get).and_return(jira_labels)
        end

        context 'when the labels field is empty' do
          let(:jira_labels) { { "maxResults" => 2, "startAt" => 0, "isLast" => true, "total" => 3, "values" => [] } }

          it_behaves_like 'no labels handling'
        end

        context 'when the labels field is missing' do
          let(:jira_labels) { { "maxResults" => 2, "startAt" => 0, "isLast" => true, "total" => 3 } }

          it_behaves_like 'no labels handling'
        end

        context 'when the isLast argument is missing' do
          let(:jira_labels) { { "maxResults" => 2, "startAt" => 0, "total" => 3, "values" => %w(bug dev) } }

          it_behaves_like 'no labels handling'
        end
      end
    end
  end
end
