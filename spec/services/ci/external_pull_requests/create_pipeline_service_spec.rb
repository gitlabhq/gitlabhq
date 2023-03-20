# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExternalPullRequests::CreatePipelineService, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:project) { create(:project, :auto_devops, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:pull_request) { create(:external_pull_request, project: project) }

    before do
      project.add_maintainer(user)
    end

    subject(:execute) { described_class.new(project, user).execute(pull_request) }

    context 'when pull request is open' do
      before do
        pull_request.update!(status: :open)
      end

      context 'when source sha is the head of the source branch' do
        let(:source_branch) { project.repository.branches.last }

        before do
          pull_request.update!(source_branch: source_branch.name, source_sha: source_branch.target)
        end

        it 'enqueues Ci::ExternalPullRequests::CreatePipelineWorker' do
          expect { execute }
            .to change { ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.count }
            .by(1)

          args = ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.last['args']

          expect(args[0]).to eq(project.id)
          expect(args[1]).to eq(user.id)
          expect(args[2]).to eq(pull_request.id)
        end
      end

      context 'when source sha is not the head of the source branch (force push upon rebase)' do
        let(:source_branch) { project.repository.branches.first }
        let(:commit) { project.repository.commits(source_branch.name, limit: 2).last }

        before do
          pull_request.update!(source_branch: source_branch.name, source_sha: commit.sha)
        end

        it 'does nothing', :aggregate_failures do
          expect { execute }
            .not_to change { ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.count }

          expect(execute).to be_error
          expect(execute.message).to eq('The source sha is not the head of the source branch')
          expect(execute.payload).to be_nil
        end
      end
    end

    context 'when pull request is not opened' do
      before do
        pull_request.update!(status: :closed)
      end

      it 'does nothing', :aggregate_failures do
        expect { execute }
          .not_to change { ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.count }

        expect(execute).to be_error
        expect(execute.message).to eq('The pull request is not opened')
        expect(execute.payload).to be_nil
      end
    end
  end
end
