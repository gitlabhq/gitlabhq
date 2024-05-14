# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::KubernetesAgentCounter do
  described_class::KNOWN_EVENTS.each do |event|
    it_behaves_like 'a redis usage counter', 'Kubernetes Agent', event
    it_behaves_like 'a redis usage counter with totals', :kubernetes_agent, event => 1
  end

  describe '.increment_event_counts' do
    let(:events) do
      {
        'k8s_api_proxy_request' => 2,
        'flux_git_push_notifications_total' => 3,
        'k8s_api_proxy_requests_via_ci_access' => 4,
        'k8s_api_proxy_requests_via_user_access' => 5,
        'k8s_api_proxy_requests_via_pat_access' => 6
      }
    end

    subject { described_class.increment_event_counts(events) }

    it 'increments the specified counters by the new increment amount' do
      described_class.increment_event_counts(events)
      described_class.increment_event_counts(events)
      described_class.increment_event_counts(events)

      expect(described_class.totals).to eq(
        kubernetes_agent_k8s_api_proxy_request: 6,
        kubernetes_agent_flux_git_push_notifications_total: 9,
        kubernetes_agent_k8s_api_proxy_requests_via_ci_access: 12,
        kubernetes_agent_k8s_api_proxy_requests_via_user_access: 15,
        kubernetes_agent_k8s_api_proxy_requests_via_pat_access: 18
      )
    end

    context 'with empty events' do
      let(:events) { nil }

      it { expect { subject }.not_to change(described_class, :totals) }
    end

    context 'event is unknown' do
      let(:events) do
        {
          'other_event' => 2
        }
      end

      it 'raises an ArgumentError' do
        expect(described_class).not_to receive(:increment_by)

        expect { subject }.to raise_error(ArgumentError, 'unknown event other_event')
      end
    end

    context 'increment is negative' do
      let(:events) do
        {
          'k8s_api_proxy_request' => -2
        }
      end

      it 'raises an ArgumentError' do
        expect(described_class).not_to receive(:increment_by)

        expect do
          subject
        end.to raise_error(ArgumentError, 'k8s_api_proxy_request count must be greater than or equal to zero')
      end
    end
  end
end
