# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CreateFromTemplateService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:template_name) { 'rails' }
  let(:project_params) do
    {
        path: user.to_param,
        template_name: template_name,
        description: 'project description',
        visibility_level: Gitlab::VisibilityLevel::PUBLIC
    }
  end

  subject { described_class.new(user, project_params) }

  it 'calls the importer service' do
    import_service_double = double

    allow(Projects::GitlabProjectsImportService).to receive(:new).and_return(import_service_double)
    expect(import_service_double).to receive(:execute)

    subject.execute
  end

  it 'returns the project that is created' do
    project = subject.execute

    expect(project).to be_saved
    expect(project.import_scheduled?).to be(true)
  end

  context 'when template is not present' do
    let(:template_name) { 'non_existent' }
    let(:project) { subject.execute }

    before do
      expect(project).not_to be_saved
    end

    it 'does not set import set import type' do
      expect(project.import_type).to be nil
    end

    it 'does not set import set import source' do
      expect(project.import_source).to be nil
    end

    it 'is not scheduled' do
      expect(project.import_scheduled?).to be(false)
    end

    it 'repository is empty' do
      expect(project.repository.empty?).to be(true)
    end
  end

  context 'the result project' do
    before do
      perform_enqueued_jobs do
        @project = subject.execute
      end

      @project.reload
    end

    it 'overrides template description' do
      expect(@project.description).to match('project description')
    end

    it 'overrides template visibility_level' do
      expect(@project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end
  end
end
