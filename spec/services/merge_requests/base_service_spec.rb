# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::BaseService do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:title) { 'Awesome merge_request' }
  let(:params) do
    {
      title: title,
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master'
    }
  end

  subject { MergeRequests::CreateService.new(project: project, current_user: project.owner, params: params) }

  describe '#execute_hooks' do
    shared_examples 'enqueues Jira sync worker' do
      specify :aggregate_failures do
        expect(JiraConnect::SyncMergeRequestWorker).to receive(:perform_async).with(kind_of(Numeric), kind_of(Numeric)).and_call_original
        Sidekiq::Testing.fake! do
          expect { subject.execute }.to change(JiraConnect::SyncMergeRequestWorker.jobs, :size).by(1)
        end
      end
    end

    shared_examples 'does not enqueue Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.not_to change(JiraConnect::SyncMergeRequestWorker.jobs, :size)
        end
      end
    end

    context 'with a Jira subscription' do
      before do
        create(:jira_connect_subscription, namespace: project.namespace)
      end

      context 'MR contains Jira issue key' do
        let(:title) { 'Awesome merge_request with issue JIRA-123' }

        it_behaves_like 'enqueues Jira sync worker'
      end

      context 'MR does not contain Jira issue key' do
        it_behaves_like 'does not enqueue Jira sync worker'
      end
    end

    context 'without a Jira subscription' do
      it_behaves_like 'does not enqueue Jira sync worker'
    end
  end
end
