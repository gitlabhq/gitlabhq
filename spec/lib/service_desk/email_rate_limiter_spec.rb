# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::EmailRateLimiter, :clean_gitlab_redis_rate_limiting, :freeze_time,
  feature_category: :service_desk do
  let_it_be(:plan) { create(:default_plan) }
  let_it_be_with_reload(:project) { create(:project, service_desk_enabled: true) }
  let_it_be(:root_namespace) { project.root_namespace }

  let(:limiter) { described_class.new(project) }

  before do
    allow(::ServiceDesk).to receive(:enabled?).and_return(true)
  end

  shared_examples 'a project that is never rate limited' do
    specify do
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
          stub_feature_flags(service_desk_email_rate_limit: false)
        end

        it_behaves_like 'a project that is never rate limited'
      end
    end

    context 'when both limits are 0' do
      it_behaves_like 'a project that is never rate limited'
    end

    context 'when only the hourly limit is set' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 3)
      end

      it 'suppresses the batch once the hourly limit is exceeded' do
        3.times { expect(limiter.rate_limit_batch!(1)).to be(false) }

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'suppresses a batch that straddles the limit and still consumes the budget' do
        limiter.rate_limit_batch!(2)

        expect(limiter.rate_limit_batch!(2)).to be(true)
        expect(limiter.rate_limit_batch!(1)).to be(true)
      end
    end

    context 'when only the daily limit is set' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_day: 2)
      end

      it 'suppresses the batch once the daily limit is exceeded' do
        2.times { expect(limiter.rate_limit_batch!(1)).to be(false) }

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end
    end

    context 'when both limits are set and the hourly limit trips first' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1,
          service_desk_outbound_emails_per_day: 100)
      end

      it 'is throttled when either window trips' do
        expect(limiter.rate_limit_batch!(1)).to be(false)

        expect(limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'increments both windows even when only one trips (no short-circuit)' do
        limiter.rate_limit_batch!(1)
        limiter.rate_limit_batch!(1)

        daily_key = "labkit:rl:{applimiter_service_desk_outbound_emails_per_day" \
          ":limit_service_desk_outbound_emails_per_day_by_namespace:namespace:#{root_namespace.id}}"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(daily_key) }

        expect(count.to_i).to eq(2)
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
        limiter.rate_limit_batch!(1)

        expect_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          expect(logger).to receive(:warn).once.and_call_original
        end

        expect(limiter.rate_limit_batch!(10)).to be(true)
      end

      it 'logs the namespace attribution and limit details in standard labkit fields' do
        limiter.rate_limit_batch!(1)

        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        limiter.rate_limit_batch!(3)

        expect(payload).to include(
          Labkit::Fields::LOG_MESSAGE => 'Service Desk outbound email rate limit exceeded',
          Labkit::Fields::CLASS_NAME => described_class.name,
          Labkit::Fields::GL_NAMESPACE_ID => project.namespace_id,
          Labkit::Fields::GL_ROOT_NAMESPACE_ID => root_namespace.id,
          Labkit::Fields::GL_PROJECT_ID => project.id
        )

        # A String rather than a Hash: the other ADDITIONAL_DETAILS call site in
        # this feature logs a string, and a scalar/object conflict in the same
        # Elasticsearch field drops the whole log line.
        details = payload[Labkit::Fields::ADDITIONAL_DETAILS]
        expect(details).to be_a(String)
        expect(details).to include(
          "exceeded_windows: 'hourly'", 'suppressed_email_count: 3', 'hourly_limit: 1', 'daily_limit: 50'
        )
      end

      it 'records both windows when both are exhausted' do
        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        # Exhausts the hourly limit of 1 and the daily limit of 50 in one batch.
        expect(limiter.rate_limit_batch!(60)).to be(true)

        expect(payload[Labkit::Fields::ADDITIONAL_DETAILS]).to include("exceeded_windows: 'hourly,daily'")
      end

      it 'does not log recipient email addresses' do
        limiter.rate_limit_batch!(1)

        payload = nil
        allow_next_instance_of(::Gitlab::AppJsonLogger) do |logger|
          allow(logger).to receive(:warn) { |args| payload = args }
        end

        limiter.rate_limit_batch!(1)

        expect(payload.values.join(' ')).not_to include('@')
      end
    end

    describe 'scope' do
      before_all do
        create(:plan_limits, plan: plan, service_desk_outbound_emails_per_hour: 1)
      end

      it 'shares the counter across sibling projects in the same namespace' do
        sibling_project = create(:project, namespace: project.namespace, service_desk_enabled: true)
        sibling_limiter = described_class.new(sibling_project)

        expect(limiter.rate_limit_batch!(1)).to be(false)
        expect(sibling_limiter.rate_limit_batch!(1)).to be(true)
      end

      it 'isolates the counter across different namespaces' do
        other_project = create(:project, service_desk_enabled: true)
        other_limiter = described_class.new(other_project)

        expect(limiter.rate_limit_batch!(1)).to be(false)
        expect(other_limiter.rate_limit_batch!(1)).to be(false)
      end
    end
  end

  describe '#post_suppression_notice' do
    let_it_be(:support_bot) { create(:support_bot) }
    let_it_be_with_reload(:work_item) { create(:work_item, :ticket, project: project, author: support_bot) }

    it 'posts a single internal note authored by the support bot' do
      expect { limiter.post_suppression_notice(work_item) }.to change { work_item.notes.count }.by(1)

      note = work_item.notes.last
      expect(note).to be_confidential
      expect(note.author).to eq(Users::Internal.in_organization(project.organization_id).support_bot)
    end

    it 'does not include recipient email addresses in the note body' do
      limiter.post_suppression_notice(work_item)

      expect(work_item.notes.last.note).not_to match(/@/)
    end

    it 'does not post a second note for the same work item within the window' do
      limiter.post_suppression_notice(work_item)

      expect { limiter.post_suppression_notice(work_item) }.not_to change { work_item.notes.count }
    end

    it 'posts its own note for a different work item' do
      other_work_item = create(:work_item, :ticket, project: project, author: support_bot)

      limiter.post_suppression_notice(work_item)

      expect { limiter.post_suppression_notice(other_work_item) }.to change { other_work_item.notes.count }.by(1)
    end

    # The support bot loses :mark_note_as_internal when Service Desk is
    # disabled for the project, and Notes::CreateService would then silently
    # save a public note that external participants can read.
    context 'when the support bot cannot mark the note as internal' do
      before do
        allow(::ServiceDesk).to receive(:enabled?).and_return(false)
      end

      it 'does not post a note at all' do
        expect { limiter.post_suppression_notice(work_item) }.not_to change { work_item.notes.count }
      end

      it 'does not consume the dedup budget, so a later eligible notice still posts' do
        limiter.post_suppression_notice(work_item)

        allow(::ServiceDesk).to receive(:enabled?).and_return(true)

        expect { limiter.post_suppression_notice(work_item) }.to change { work_item.notes.count }.by(1)
      end
    end
  end
end
