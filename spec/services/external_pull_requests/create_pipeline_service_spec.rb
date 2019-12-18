# frozen_string_literal: true

require 'spec_helper'

describe ExternalPullRequests::CreatePipelineService do
  describe '#execute' do
    set(:project) { create(:project, :auto_devops, :repository) }
    set(:user) { create(:user) }
    let(:pull_request) { create(:external_pull_request, project: project) }

    before do
      project.add_maintainer(user)
    end

    subject { described_class.new(project, user).execute(pull_request) }

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

        it 'creates a pipeline for external pull request' do
          expect(subject).to be_valid
          expect(subject).to be_persisted
          expect(subject).to be_external_pull_request_event
          expect(subject).to eq(project.ci_pipelines.last)
          expect(subject.external_pull_request).to eq(pull_request)
          expect(subject.user).to eq(user)
          expect(subject.status).to eq('pending')
          expect(subject.ref).to eq(pull_request.source_branch)
          expect(subject.sha).to eq(pull_request.source_sha)
          expect(subject.source_sha).to eq(pull_request.source_sha)
        end
      end

      context 'when source sha is not the head of the source branch (force push upon rebase)' do
        let(:source_branch) { project.repository.branches.first }
        let(:commit) { project.repository.commits(source_branch.name, limit: 2).last }

        before do
          pull_request.update!(source_branch: source_branch.name, source_sha: commit.sha)
        end

        it 'does nothing' do
          expect(Ci::CreatePipelineService).not_to receive(:new)

          expect(subject).to be_nil
        end
      end
    end

    context 'when pull request is not opened' do
      before do
        pull_request.update!(status: :closed)
      end

      it 'does nothing' do
        expect(Ci::CreatePipelineService).not_to receive(:new)

        expect(subject).to be_nil
      end
    end
  end
end
