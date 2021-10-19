# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GenerateKubeconfigService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:build) { create(:ci_build, project: project) }
    let(:agent1) { create(:cluster_agent, project: project) }
    let(:agent2) { create(:cluster_agent) }

    let(:template) { instance_double(Gitlab::Kubernetes::Kubeconfig::Template) }

    subject { described_class.new(build).execute }

    before do
      expect(Gitlab::Kubernetes::Kubeconfig::Template).to receive(:new).and_return(template)
      expect(build.pipeline).to receive(:authorized_cluster_agents).and_return([agent1, agent2])
    end

    it 'adds a cluster, and a user and context for each available agent' do
      expect(template).to receive(:add_cluster).with(
        name: 'gitlab',
        url: Gitlab::Kas.tunnel_url
      ).once

      expect(template).to receive(:add_user).with(
        name: "agent:#{agent1.id}",
        token: "ci:#{agent1.id}:#{build.token}"
      )
      expect(template).to receive(:add_user).with(
        name: "agent:#{agent2.id}",
        token: "ci:#{agent2.id}:#{build.token}"
      )

      expect(template).to receive(:add_context).with(
        name: "#{project.full_path}:#{agent1.name}",
        cluster: 'gitlab',
        user: "agent:#{agent1.id}"
      )
      expect(template).to receive(:add_context).with(
        name: "#{agent2.project.full_path}:#{agent2.name}",
        cluster: 'gitlab',
        user: "agent:#{agent2.id}"
      )

      expect(subject).to eq(template)
    end
  end
end
