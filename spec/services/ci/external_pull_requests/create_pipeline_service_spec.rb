# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExternalPullRequests::CreatePipelineService do
  describe '#execute' do
    let_it_be(:project) { create(:project, :auto_devops, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:pull_request) { create(:external_pull_request, project: project) }

    before do
      project.add_maintainer(user)
    end

    subject(:response) { described_class.new(project, user).execute(pull_request) }

    context 'when pull request is open' do
      before do
        pull_request.update!(status: :open)
      end

      context 'when source sha is the head of the source branch' do
        let(:source_branch) { project.repository.branches.last }
        let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }

        before do
          pull_request.update!(source_branch: source_branch.name, source_sha: source_branch.target)
        end

        it 'creates a pipeline for external pull request', :aggregate_failures do
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_valid
          expect(pipeline).to be_persisted
          expect(pipeline).to be_external_pull_request_event
          expect(pipeline).to eq(project.ci_pipelines.last)
          expect(pipeline.external_pull_request).to eq(pull_request)
          expect(pipeline.user).to eq(user)
          expect(pipeline.status).to eq('created')
          expect(pipeline.ref).to eq(pull_request.source_branch)
          expect(pipeline.sha).to eq(pull_request.source_sha)
          expect(pipeline.source_sha).to eq(pull_request.source_sha)
        end
      end

      context 'when source sha is not the head of the source branch (force push upon rebase)' do
        let(:source_branch) { project.repository.branches.first }
        let(:commit) { project.repository.commits(source_branch.name, limit: 2).last }

        before do
          pull_request.update!(source_branch: source_branch.name, source_sha: commit.sha)
        end

        it 'does nothing', :aggregate_failures do
          expect(Ci::CreatePipelineService).not_to receive(:new)

          expect(response).to be_error
          expect(response.message).to eq('The source sha is not the head of the source branch')
          expect(response.payload).to be_nil
        end
      end
    end

    context 'when pull request is not opened' do
      before do
        pull_request.update!(status: :closed)
      end

      it 'does nothing', :aggregate_failures do
        expect(Ci::CreatePipelineService).not_to receive(:new)

        expect(response).to be_error
        expect(response.message).to eq('The pull request is not opened')
        expect(response.payload).to be_nil
      end
    end
  end
end
