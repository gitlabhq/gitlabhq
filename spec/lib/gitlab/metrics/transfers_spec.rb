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
end
