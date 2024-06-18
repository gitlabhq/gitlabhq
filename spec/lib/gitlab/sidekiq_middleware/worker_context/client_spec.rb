# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::WorkerContext::Client do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestWithContextWorker'
      end

      include ApplicationWorker

      feature_category :team_planning

      def self.job_for_args(args)
        jobs.find { |job| job['args'] == args }
      end

      def perform(*args); end
    end
  end

  let(:not_owned_worker_class) do
    Class.new(worker_class) do
      def self.name
        'TestNotOwnedWithContextWorker'
      end

      feature_category :not_owned
    end
  end

  let(:mailer_class) do
    Class.new(ApplicationMailer) do
      def self.name
        'TestMailer'
      end

      def test_mail; end
    end
  end

  before do
    stub_const(worker_class.name, worker_class)
    stub_const(not_owned_worker_class.name, not_owned_worker_class)
    stub_const(mailer_class.name, mailer_class)
  end

  describe "#call" do
    context 'root_caller_id' do
      it 'uses caller_id of the current context' do
        Gitlab::ApplicationContext.with_context(caller_id: 'CALLER') do
          TestWithContextWorker.perform_async
        end

        job = TestWithContextWorker.jobs.last
        expect(job['meta.root_caller_id']).to eq('CALLER')
      end

      it 'uses root_caller_id instead of caller_id of the current context' do
        Gitlab::ApplicationContext.with_context(caller_id: 'CALLER', root_caller_id: 'ROOT_CALLER') do
          TestWithContextWorker.perform_async
        end

        job = TestWithContextWorker.jobs.last
        expect(job['meta.root_caller_id']).to eq('ROOT_CALLER')
      end
    end

    it 'applies a context for jobs scheduled in batch' do
      user_per_job = { 'job1' => build_stubbed(:user, username: 'user-1'),
                       'job2' => build_stubbed(:user, username: 'user-2') }

      TestWithContextWorker.bulk_perform_async_with_contexts(
        %w[job1 job2],
        arguments_proc: ->(name) { [name, 1, 2, 3] },
        context_proc: ->(name) { { user: user_per_job[name] } }
      )

      job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
      job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

      expect(job1['meta.user']).to eq(user_per_job['job1'].username)
      expect(job2['meta.user']).to eq(user_per_job['job2'].username)
    end

    context 'when the feature category is set in the context_proc' do
      it 'takes the feature category from the worker, not the caller' do
        TestWithContextWorker.bulk_perform_async_with_contexts(
          %w[job1 job2],
          arguments_proc: ->(name) { [name, 1, 2, 3] },
          context_proc: ->(_) { { feature_category: 'code_review' } }
        )

        job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('team_planning')
        expect(job2['meta.feature_category']).to eq('team_planning')
      end

      it 'takes the feature category from the caller if the worker is not owned' do
        TestNotOwnedWithContextWorker.bulk_perform_async_with_contexts(
          %w[job1 job2],
          arguments_proc: ->(name) { [name, 1, 2, 3] },
          context_proc: ->(_) { { feature_category: 'code_review' } }
        )

        job1 = TestNotOwnedWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestNotOwnedWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('code_review')
        expect(job2['meta.feature_category']).to eq('code_review')
      end

      it 'does not set any explicit feature category for mailers', :sidekiq_mailers do
        expect(Gitlab::ApplicationContext).to receive(:with_context).with(hash_excluding(feature_category: anything))

        TestMailer.test_mail.deliver_later
      end
    end

    context 'when the feature category is already set in the surrounding block' do
      it 'takes the feature category from the worker, not the caller' do
        Gitlab::ApplicationContext.with_context(feature_category: 'system_access') do
          TestWithContextWorker.bulk_perform_async_with_contexts(
            %w[job1 job2],
            arguments_proc: ->(name) { [name, 1, 2, 3] },
            context_proc: ->(_) { {} }
          )
        end

        job1 = TestWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('team_planning')
        expect(job2['meta.feature_category']).to eq('team_planning')
      end

      it 'takes the feature category from the caller if the worker is not owned' do
        Gitlab::ApplicationContext.with_context(feature_category: 'system_access') do
          TestNotOwnedWithContextWorker.bulk_perform_async_with_contexts(
            %w[job1 job2],
            arguments_proc: ->(name) { [name, 1, 2, 3] },
            context_proc: ->(_) { {} }
          )
        end

        job1 = TestNotOwnedWithContextWorker.job_for_args(['job1', 1, 2, 3])
        job2 = TestNotOwnedWithContextWorker.job_for_args(['job2', 1, 2, 3])

        expect(job1['meta.feature_category']).to eq('system_access')
        expect(job2['meta.feature_category']).to eq('system_access')
      end
    end
  end
end
