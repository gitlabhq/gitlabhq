# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExternalPullRequests::CreatePipelineWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :auto_devops, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:external_pull_request) do
    branch = project.repository.branches.last
    create(:external_pull_request, project: project, source_branch: branch.name, source_sha: branch.target)
  end

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:project_id) { project.id }
    let(:user_id) { user.id }
    let(:external_pull_request_id) { external_pull_request.id }

    subject(:perform) { worker.perform(project_id, user_id, external_pull_request_id) }

    it 'creates the pipeline' do
      pipeline = perform.payload

      expect(pipeline).to be_valid
      expect(pipeline).to be_persisted
      expect(pipeline).to be_external_pull_request_event
      expect(pipeline.project).to eq(project)
      expect(pipeline.user).to eq(user)
      expect(pipeline.external_pull_request).to eq(external_pull_request)
      expect(pipeline.status).to eq('created')
      expect(pipeline.ref).to eq(external_pull_request.source_branch)
      expect(pipeline.sha).to eq(external_pull_request.source_sha)
      expect(pipeline.source_sha).to eq(external_pull_request.source_sha)
      expect(pipeline.target_sha).to eq(external_pull_request.target_sha)
    end

    shared_examples_for 'not calling service' do
      it 'does not call the service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        perform
      end
    end

    context 'when the project not found' do
      let(:project_id) { non_existing_record_id }

      it_behaves_like 'not calling service'
    end

    context 'when the user not found' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'not calling service'
    end

    context 'when the pull request not found' do
      let(:external_pull_request_id) { non_existing_record_id }

      it_behaves_like 'not calling service'
    end

    context 'when the pull request does not belong to the project' do
      let(:external_pull_request_id) { create(:external_pull_request).id }

      it_behaves_like 'not calling service'
    end
  end
end
