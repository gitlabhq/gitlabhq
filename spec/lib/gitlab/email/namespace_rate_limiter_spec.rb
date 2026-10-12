# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::NamespaceRateLimiter, :clean_gitlab_redis_rate_limiting, :freeze_time,
  feature_category: :source_code_management do
  let_it_be(:plan) { create(:default_plan) }
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:root_namespace) { project.root_namespace }

  let(:feature_flag) { :service_desk_email_rate_limit }
  # Exercises the generalized class through the Service Desk bucket keys; the
  # per-feature keys are covered by the EoP and Pipelines Email specs.
  #
  let(:hourly_bucket) { :service_desk_outbound_emails_per_hour }
  let(:daily_bucket) { :service_desk_outbound_emails_per_day }
  let(:log_message) { 'Outbound email rate limit exceeded' }

  let(:limiter) do
    described_class.new(
      root_namespace: root_namespace,
      hourly_bucket: hourly_bucket,
      daily_bucket: daily_bucket,
      feature_flag: feature_flag,
      log_message: log_message
    )
  end

  shared_examples 'a namespace that is never rate limited' do
    specify :aggregate_failures do
      expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
      expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

      expect(limiter.rate_limit_batch!(1)).to be(false)
    end
  end

  describe '#rate_limit_batch!' do
    context 'when a plan limit exists' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(feature_flag => false)
        end

        it_behaves_like 'a namespace that is never rate limited'
      end

      it 'reads its threshold from the service_desk_outbound_emails plan_limit columns' do
        # limit is 1: the first batch exhausts the window, the next is suppressed.
        expect(limiter.rate_limit_batch!(2)).to be(false)

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end
    end

    context 'when both limits are 0' do
      it_behaves_like 'a namespace that is never rate limited'
    end

    context 'when a count of 0 is charged' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      it 'does not touch the rate limiter', :aggregate_failures do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        expect(limiter.rate_limit_batch!(0)).to be(false)
      end
    end

    context 'when only the hourly limit is set' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 3)
      end

      it 'sends until the window is already exhausted, then suppresses' do
        # Suppression triggers once the counter is already over, so the batch
        # that crosses the limit still sends (soft cap).
        4.times { expect(limiter.rate_limit_batch!(1)).to be(false) }

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'lets an oversized batch through once, then suppresses' do
        # A single batch larger than the window is not suppressed forever: it
        # sends once, exhausting the window, and the next batch is suppressed.
        expect(limiter.rate_limit_batch!(10)).to be(false)

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end
    end

    context 'when only the daily limit is set' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_day: 2)
      end

      it 'sends until the window is already exhausted, then suppresses' do
        3.times { expect(limiter.rate_limit_batch!(1)).to be(false) }

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end
    end

    describe 'bucket parameterization' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      it 'peeks and then charges the bucket named by hourly_bucket', :aggregate_failures do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:peek)
          .with(hourly_bucket, hash_including(scope: { namespace: root_namespace }))
          .and_return(false)
        allow(::Gitlab::ApplicationRateLimiter).to receive(:peek)
          .with(daily_bucket, hash_including(scope: { namespace: root_namespace }))
          .and_return(false)

        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(hourly_bucket, hash_including(scope: { namespace: root_namespace }, cost: 1))
          .and_call_original

        limiter.rate_limit_batch!(1)
      end
    end

    describe 'scope' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      it 'shares the counter across sibling projects in the same namespace' do
        sibling_project = create(:project, namespace: project.namespace)
        sibling_limiter = described_class.new(
          root_namespace: sibling_project.root_namespace,
          hourly_bucket: hourly_bucket,
          daily_bucket: daily_bucket,
          feature_flag: feature_flag,
          log_message: log_message
        )

        # First batch exhausts the shared window; the sibling then sees it as
        # already exceeded.
        expect(limiter.rate_limit_batch!(2)).to be(false)
        expect(sibling_limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'isolates the counter across different namespaces' do
        other_project = create(:project)
        other_limiter = described_class.new(
          root_namespace: other_project.root_namespace,
          hourly_bucket: hourly_bucket,
          daily_bucket: daily_bucket,
          feature_flag: feature_flag,
          log_message: log_message
        )

        expect(limiter.rate_limit_batch!(1)).to be(false)
        expect(other_limiter.rate_limit_batch!(1)).to be(false)
      end
    end

    describe 'logging' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1,
          service_desk_outbound_emails_per_day: 50)
      end

      it 'does not log while the batch is under the limit' do
        expect(::Gitlab::AppJsonLogger).not_to receive(:build)

        expect(limiter.rate_limit_batch!(1)).to be(false)
      end

      it 'logs once per suppressed batch, not once per email' do
        limiter.rate_limit_batch!(2)

        expect_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          expect(logger).to receive(:warn).once.and_call_original
        end

        expect(limiter.rate_limit_batch!(10)).to be(true)
      end

      it 'logs the configured message, namespace attribution, and limit details', :aggregate_failures do
        limiter.rate_limit_batch!(2)

        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        limiter.rate_limit_batch!(3)

        expect(payload).to include(
          Labkit::Fields::LOG_MESSAGE => log_message,
          Labkit::Fields::GL_ROOT_NAMESPACE_ID => root_namespace.id
        )

        # A String rather than a Hash: a scalar/object conflict in the same
        # Elasticsearch field drops the whole log line.
        #
        details = payload[Labkit::Fields::ADDITIONAL_DETAILS]
        expect(details).to be_a(String)
        expect(details).to include(
          "exceeded_windows: 'hourly'", 'suppressed_email_count: 3', 'hourly_limit: 1', 'daily_limit: 50'
        )
      end

      it 'merges the provided log_context into the payload' do
        contextual_limiter = described_class.new(
          root_namespace: root_namespace,
          hourly_bucket: hourly_bucket,
          daily_bucket: daily_bucket,
          feature_flag: feature_flag,
          log_message: log_message,
          log_context: { Labkit::Fields::GL_PROJECT_ID => project.id }
        )

        contextual_limiter.rate_limit_batch!(2)

        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        contextual_limiter.rate_limit_batch!(1)

        expect(payload).to include(Labkit::Fields::GL_PROJECT_ID => project.id)
      end

      it 'records both windows when both are exhausted' do
        # Exhaust both windows (hourly 1, daily 50) with one oversized batch,
        # then the next batch sees both as already exceeded.
        limiter.rate_limit_batch!(60)

        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        expect(limiter.rate_limit_batch!(1)).to be(true)

        expect(payload[Labkit::Fields::ADDITIONAL_DETAILS]).to include("exceeded_windows: 'hourly,daily'")
      end
    end
  end

  describe '#rate_limit_batch! with overshoot: :hard_cap' do
    let(:limiter) do
      described_class.new(
        root_namespace: root_namespace,
        hourly_bucket: hourly_bucket,
        daily_bucket: daily_bucket,
        feature_flag: feature_flag,
        log_message: log_message,
        overshoot: :hard_cap
      )
    end

    context 'when the hourly limit is 1' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      it 'suppresses the batch that trips the window and stays suppressed', :aggregate_failures do
        # Strict: limit 1, batch 2 trips the window, so the whole batch is
        # suppressed all-or-none. The counter is still charged, so the next
        # batch in the same window also suppresses.
        #
        expect(limiter.rate_limit_batch!(2)).to be(true)

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'does not suppress a batch that stays within the window' do
        expect(limiter.rate_limit_batch!(1)).to be(false)
      end
    end

    context 'when both limits are 0' do
      it_behaves_like 'a namespace that is never rate limited'
    end
  end

  describe '#initialize' do
    it 'rejects an unknown overshoot mode' do
      expect do
        described_class.new(
          root_namespace: root_namespace,
          hourly_bucket: hourly_bucket,
          daily_bucket: daily_bucket,
          feature_flag: feature_flag,
          log_message: log_message,
          overshoot: :nonsense
        )
      end.to raise_error(ArgumentError, /unknown overshoot mode/)
    end
  end

  describe '.rate_limit_batch_for_project!' do
    let(:args) do
      {
        class_name: 'EmailsOnPushWorker',
        hourly_bucket: hourly_bucket,
        daily_bucket: daily_bucket,
        feature_flag: feature_flag,
        log_message: log_message,
        count: 1
      }
    end

    it 'delegates to an instance and charges the batch' do
      expect(described_class.rate_limit_batch_for_project!(project: project, **args)).to be(false)
    end
  end
end
