# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabServicePingWorker, :clean_gitlab_redis_shared_state, feature_category: :service_ping do
  let(:payload) { { recorded_at: Time.current.rfc3339 } }
  let(:non_sql_payload) { { recorded_at: Time.current.rfc3339, count: 123 } }
  let(:queries_payload) { { recorded_at: Time.current.rfc3339, users_count: "SELECT COUNT(*) FROM users" } }

  before do
    allow_next_instance_of(ServicePing::SubmitService) { |service| allow(service).to receive(:execute) }
    allow_next_instance_of(ServicePing::BuildPayload) do |service|
      allow(service).to receive(:execute).and_return(payload)
    end
    allow(Gitlab::Usage::ServicePingReport).to receive(:for)
      .with(output: :non_sql_metrics_values).and_return(non_sql_payload)
    allow(Gitlab::Usage::ServicePingReport).to receive(:for)
      .with(output: :metrics_queries).and_return(queries_payload)

    allow(subject).to receive(:sleep)
    create(:organization)
  end

  it 'does not run for SaaS when triggered from cron', :saas do
    expect(ServicePing::SubmitService).not_to receive(:new)

    subject.perform
  end

  it 'runs for SaaS when triggered manually', :saas do
    expect(ServicePing::SubmitService).to receive(:new)

    subject.perform('triggered_from_cron' => false)
  end

  it 'delegates to ServicePing::SubmitService' do
    expect_next_instance_of(ServicePing::SubmitService, payload: payload) do |service|
      expect(service).to receive(:execute)
    end

    subject.perform
  end

  context 'payload computation' do
    describe "RawUsageData creation" do
      it 'creates RawUsageData entry when there is NO entry with the same recorded_at timestamp' do
        expect { subject.perform }.to change { RawUsageData.count }.by(1)
      end

      it 'updates RawUsageData entry when there is entry with the same recorded_at timestamp' do
        record = create(:raw_usage_data, payload: { some_metric: 123 }, recorded_at: payload[:recorded_at])

        expect { subject.perform }.to change { record.reload.payload }
                                        .from("some_metric" => 123).to(payload.stringify_keys)
      end

      it 'reports errors and continue on execution' do
        error = StandardError.new('some error')
        allow(::ServicePing::BuildPayload).to receive(:new).and_raise(error)

        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect_next_instance_of(::ServicePing::SubmitService, payload: nil) do |service|
          expect(service).to receive(:execute)
        end

        subject.perform
      end
    end

    describe "NonSqlServicePing creation" do
      it 'creates NonSqlServicePing entry when there is NO entry with the same recorded_at timestamp' do
        expect { subject.perform }.to change { ServicePing::NonSqlServicePing.count }.by(1)
      end

      it 'updates NonSqlServicePing entry when there is entry with the same recorded_at timestamp' do
        record = create(
          :non_sql_service_ping,
          payload: { some_metric: 123 },
          recorded_at: non_sql_payload[:recorded_at]
        )

        expect { subject.perform }.to change { record.reload.payload }
                                        .from("some_metric" => 123).to(non_sql_payload.stringify_keys)
      end

      it 'reports errors and continue on execution' do
        error = StandardError.new('some error')
        allow(::Gitlab::Usage::ServicePingReport).to receive(:for)
          .with(output: :non_sql_metrics_values).and_raise(error)

        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect_next_instance_of(::ServicePing::SubmitService, payload: payload) do |service|
          expect(service).to receive(:execute)
        end

        subject.perform
      end
    end

    describe "QueriesServicePing creation" do
      it 'creates QueriesServicePing entry when there is NO entry with the same recorded_at timestamp' do
        expect { subject.perform }.to change { ServicePing::QueriesServicePing.count }.by(1)
      end

      it 'updates QueriesServicePing entry when there is entry with the same recorded_at timestamp' do
        record = create(
          :non_sql_service_ping,
          payload: { some_metric: "SELECT 123" },
          recorded_at: non_sql_payload[:recorded_at]
        )

        expect { subject.perform }.to change { record.reload.payload }
                                        .from("some_metric" => "SELECT 123").to(non_sql_payload.stringify_keys)
      end

      it 'reports errors and continue on execution' do
        error = StandardError.new('some error')
        allow(::Gitlab::Usage::ServicePingReport).to receive(:for)
          .with(output: :metrics_queries).and_raise(error)

        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect_next_instance_of(::ServicePing::SubmitService, payload: payload) do |service|
          expect(service).to receive(:execute)
        end

        subject.perform
      end
    end
  end

  it "obtains a #{described_class::LEASE_TIMEOUT} second exclusive lease" do
    expect(Gitlab::ExclusiveLeaseHelpers::SleepingLock)
      .to receive(:new)
      .with(described_class::LEASE_KEY, hash_including(timeout: described_class::LEASE_TIMEOUT))
      .and_call_original

    expect(Gitlab::ExclusiveLeaseHelpers::SleepingLock)
      .to receive(:new)
      .with(described_class::NON_SQL_LEASE_KEY, hash_including(timeout: described_class::LEASE_TIMEOUT))
      .and_call_original

    expect(Gitlab::ExclusiveLeaseHelpers::SleepingLock)
      .to receive(:new)
      .with(described_class::QUERIES_LEASE_KEY, hash_including(timeout: described_class::LEASE_TIMEOUT))
      .and_call_original

    subject.perform
  end

  it 'sleeps for between 0 and 60 seconds' do
    expect(subject).to receive(:sleep).with(0..60)

    subject.perform
  end

  context 'when lease is not obtained' do
    before do
      Gitlab::ExclusiveLease.new(described_class::LEASE_KEY, timeout: described_class::LEASE_TIMEOUT).try_obtain
    end

    it 'does not invoke ServicePing::SubmitService' do
      allow_next_instance_of(ServicePing::SubmitService) { |service| expect(service).not_to receive(:execute) }

      expect { subject.perform }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
