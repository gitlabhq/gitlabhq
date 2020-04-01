# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::LabelsImporter do
  let(:user) { create(:user) }
  let(:jira_import_data) do
    data = JiraImportData.new
    data << JiraImportData::JiraProjectDetails.new('XX', Time.now.strftime('%Y-%m-%d %H:%M:%S'), { user_id: user.id, name: user.name })
    data
  end
  let(:project) { create(:project, import_data: jira_import_data) }
  let!(:jira_service) { create(:jira_service, project: project) }

  subject { described_class.new(project).execute }

  before do
    stub_feature_flags(jira_issue_import: true)
  end

  describe '#execute', :clean_gitlab_redis_cache do
    context 'when label creation failes' do
      before do
        allow_next_instance_of(Labels::CreateService) do |instance|
          allow(instance).to receive(:execute).and_return(nil)
        end
      end

      it 'raises error' do
        expect { subject }.to raise_error(Projects::ImportService::Error, 'Failed to create import label for jira import.')
      end
    end

    context 'when label is created successfully' do
      it 'creates import label' do
        expect { subject }.to change { Label.count }.by(1)
      end

      it 'caches import label' do
        expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.import_label_cache_key(project.id))).to be nil

        subject

        expect(Gitlab::JiraImport.get_import_label_id(project.id).to_i).to be > 0
      end
    end
  end
end
