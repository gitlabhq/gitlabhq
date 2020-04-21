# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::LabelsImporter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_service) { create(:jira_service, project: project) }

  subject { described_class.new(project).execute }

  before do
    stub_feature_flags(jira_issue_import: true)
  end

  describe '#execute', :clean_gitlab_redis_cache do
    context 'when label is missing from jira import' do
      let_it_be(:no_label_jira_import) { create(:jira_import_state, label: nil, project: project) }

      it 'raises error' do
        expect { subject }.to raise_error(Projects::ImportService::Error, 'Failed to find import label for Jira import.')
      end
    end

    context 'when label exists' do
      let_it_be(:label) { create(:label) }
      let_it_be(:jira_import_with_label) { create(:jira_import_state, label: label, project: project) }

      it 'caches import label' do
        expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.import_label_cache_key(project.id))).to be nil

        subject

        expect(Gitlab::JiraImport.get_import_label_id(project.id).to_i).to eq(label.id)
      end
    end
  end
end
