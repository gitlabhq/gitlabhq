# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::KubernetesAgentCounter do
  it_behaves_like 'a redis usage counter', 'Kubernetes Agent', :gitops_sync

  it_behaves_like 'a redis usage counter with totals', :kubernetes_agent, gitops_sync: 1

  describe '.increment_gitops_sync' do
    it 'increments the gtops_sync counter by the new increment amount' do
      described_class.increment_gitops_sync(7)
      described_class.increment_gitops_sync(2)
      described_class.increment_gitops_sync(0)

      expect(described_class.totals).to eq(kubernetes_agent_gitops_sync: 9)
    end

    it 'raises for negative numbers' do
      expect { described_class.increment_gitops_sync(-1) }.to raise_error(ArgumentError)
    end
  end
end
