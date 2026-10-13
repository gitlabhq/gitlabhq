# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Transfers, :prometheus, feature_category: :groups_and_projects do
  describe '.count_transfer' do
    it 'increments the gitlab_namespace_transfer_total counter' do
      expect { described_class.count_transfer(namespace_type: 'group', result: 'success') }
        .to change {
          ::Prometheus::Client.registry.get(:gitlab_namespace_transfer_total)
            &.get(namespace_type: 'group', result: 'success')
            .to_i
        }.by(1)
    end

    it 'supports different label combinations', :aggregate_failures do
      described_class.count_transfer(namespace_type: 'project', result: 'failure')

      counter = ::Prometheus::Client.registry.get(:gitlab_namespace_transfer_total)
      expect(counter).not_to be_nil
      expect(counter.get(namespace_type: 'project', result: 'failure')).to eq(1)
    end
  end

  describe '.observe_transfer_duration' do
    it 'observes a value in the gitlab_namespace_transfer_duration_seconds histogram' do
      described_class.observe_transfer_duration(duration_s: 2.5, namespace_type: 'group')

      histogram = ::Prometheus::Client.registry.get(:gitlab_namespace_transfer_duration_seconds)
      expect(histogram).not_to be_nil
    end

    it 'accepts project namespace_type' do
      expect do
        described_class.observe_transfer_duration(duration_s: 10.0, namespace_type: 'project')
      end.not_to raise_error
    end
  end

  describe '.observe_end_to_end_transfer_duration' do
    let(:histogram) { instance_double(Prometheus::Client::Histogram) }

    before do
      allow(::Gitlab::Metrics).to receive(:histogram)
        .with(:gitlab_namespace_transfer_end_to_end_duration_seconds, anything, {},
          described_class::END_TO_END_DURATION_BUCKETS)
        .and_return(histogram)
    end

    it 'observes the seconds elapsed since scheduled_at', :freeze_time do
      expect(histogram).to receive(:observe).with({ namespace_type: 'project' }, 7200.0)

      described_class.observe_end_to_end_transfer_duration(
        scheduled_at: 2.hours.ago.as_json,
        namespace_type: 'project'
      )
    end

    it 'observes zero when scheduled_at is in the future', :freeze_time do
      expect(histogram).to receive(:observe).with({ namespace_type: 'group' }, 0.0)

      described_class.observe_end_to_end_transfer_duration(
        scheduled_at: 5.seconds.from_now.as_json,
        namespace_type: 'group'
      )
    end

    where(scheduled_at: [nil, 'not-a-date', '2026-99-99T00:00:00Z', 123])

    with_them do
      it 'does not observe anything' do
        expect(histogram).not_to receive(:observe)

        described_class.observe_end_to_end_transfer_duration(scheduled_at: scheduled_at, namespace_type: 'group')
      end
    end
  end
end
