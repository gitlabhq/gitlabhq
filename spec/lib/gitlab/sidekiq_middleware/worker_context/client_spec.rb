# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::WorkerContext::Client do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestWithContextWorker'
      end

      include ApplicationWorker

      feature_category :issue_tracking

      def self.job_for_args(args)
        jobs.find { |job| job['args'] == args }
      end

      def perform(*args)
      end
    end
  end

  before do
    stub_const('TestWithContextWorker', worker_class)
  end

  describe "#call" do
    it 'applies a context for jobs scheduled in batch' do
      user_per_job = { 'job1' => build_stubbed(:user, username: 'user-1'),
                       'job2' => build_stubbed(:user, username: 'user-2') }

      TestWithContextWorker.bulk_perform_async_with_contexts(
        %w(job1 job2),
        arguments_proc: -> (name) { [name, 1, 2, 3] },
        context_proc: -> (name) { { user: user_per_job[name] } }
      )

      job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
      job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

      expect(job1['meta.user']).to eq(user_per_job['job1'].username)
      expect(job2['meta.user']).to eq(user_per_job['job2'].username)
    end

    context 'when the feature category is set in the context_proc' do
      it 'takes the feature category from the worker, not the caller' do
        TestWithContextWorker.bulk_perform_async_with_contexts(
          %w(job1 job2),
          arguments_proc: -> (name) { [name, 1, 2, 3] },
          context_proc: -> (_) { { feature_category: 'code_review' } }
        )

        job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('issue_tracking')
        expect(job2['meta.feature_category']).to eq('issue_tracking')
      end
    end

    context 'when the feature category is already set in the surrounding block' do
      it 'takes the feature category from the worker, not the caller' do
        Gitlab::ApplicationContext.with_context(feature_category: 'authentication_and_authorization') do
          TestWithContextWorker.bulk_perform_async_with_contexts(
            %w(job1 job2),
            arguments_proc: -> (name) { [name, 1, 2, 3] },
            context_proc: -> (_) { {} }
          )
        end

        job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('issue_tracking')
        expect(job2['meta.feature_category']).to eq('issue_tracking')
      end
    end
  end
end
