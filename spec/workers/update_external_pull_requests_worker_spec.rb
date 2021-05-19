# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateExternalPullRequestsWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project, import_source: 'tanuki/repository') }
    let_it_be(:user) { create(:user) }

    let(:worker) { described_class.new }

    before do
      create(:external_pull_request,
        project: project,
        source_repository: project.import_source,
        target_repository: project.import_source,
        source_branch: 'feature-1',
        target_branch: 'master')

      create(:external_pull_request,
        project: project,
        source_repository: project.import_source,
        target_repository: project.import_source,
        source_branch: 'feature-1',
        target_branch: 'develop')
    end

    subject { worker.perform(project.id, user.id, ref) }

    context 'when ref is a branch' do
      let(:ref) { 'refs/heads/feature-1' }
      let(:create_pipeline_service) { instance_double(Ci::ExternalPullRequests::CreatePipelineService) }

      it 'runs CreatePipelineService for each pull request matching the source branch and repository' do
        expect(Ci::ExternalPullRequests::CreatePipelineService)
          .to receive(:new)
          .and_return(create_pipeline_service)
          .twice
        expect(create_pipeline_service).to receive(:execute).twice

        subject
      end
    end

    context 'when ref is not a branch' do
      let(:ref) { 'refs/tags/v1.2.3' }

      it 'does nothing' do
        expect(Ci::ExternalPullRequests::CreatePipelineService).not_to receive(:new)

        subject
      end
    end
  end
end
