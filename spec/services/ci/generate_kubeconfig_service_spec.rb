# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GenerateKubeconfigService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }
    let_it_be(:build) { create(:ci_build, project: project, pipeline: pipeline) }

    let_it_be(:agent_project) { create(:project, group: group, name: 'project-containing-agent-config') }

    let_it_be(:project_agent_authorization) do
      agent = create(:cluster_agent, project: agent_project)
      create(:agent_ci_access_project_authorization, agent: agent, project: project)
    end

    let_it_be(:group_agent_authorization) do
      agent = create(:cluster_agent, project: agent_project)
      create(:agent_ci_access_group_authorization, agent: agent, group: group)
    end

    let(:template) do
      instance_double(
        Gitlab::Kubernetes::Kubeconfig::Template,
        add_cluster: nil,
        add_user: nil,
        add_context: nil
      )
    end

    let(:agent_authorizations) { [project_agent_authorization, group_agent_authorization] }
    let(:filter_service) do
      instance_double(
        ::Clusters::Agents::Authorizations::CiAccess::FilterService,
        execute: agent_authorizations
      )
    end

    subject(:execute) { described_class.new(pipeline, token: build.token, environment: nil).execute }

    before do
      allow(Gitlab::Kubernetes::Kubeconfig::Template).to receive(:new).and_return(template)
      allow(::Clusters::Agents::Authorizations::CiAccess::FilterService).to receive(:new).and_return(filter_service)
    end

    it 'returns a Kubeconfig Template' do
      expect(execute).to eq(template)
    end

    it 'adds a cluster' do
      expect(template).to receive(:add_cluster).with(
        name: 'gitlab',
        url: Gitlab::Kas.tunnel_url
      ).once

      execute
    end

    it "filters the pipeline's agents by `nil` environment" do
      expect(::Clusters::Agents::Authorizations::CiAccess::FilterService).to receive(:new).with(
        pipeline.cluster_agent_authorizations,
        { environment: nil,
          protected_ref: false },
        project
      )

      execute
    end

    it 'adds user and context for all eligible agents', :aggregate_failures do
      agent_authorizations.each do |authorization|
        expect(template).to receive(:add_user).with(
          name: "agent:#{authorization.agent.id}",
          token: "ci:#{authorization.agent.id}:#{build.token}"
        )

        expect(template).to receive(:add_context).with(
          name: "#{agent_project.full_path}:#{authorization.agent.name}",
          namespace: 'production',
          cluster: 'gitlab',
          user: "agent:#{authorization.agent.id}"
        )
      end

      execute
    end

    context 'when environment is specified' do
      subject(:execute) { described_class.new(pipeline, token: build.token, environment: 'production').execute }

      it "filters the pipeline's agents by the specified environment" do
        expect(::Clusters::Agents::Authorizations::CiAccess::FilterService).to receive(:new).with(
          pipeline.cluster_agent_authorizations,
          { environment: 'production',
            protected_ref: false },
          project
        )

        execute
      end
    end
  end
end
