# frozen_string_literal: true
require 'spec_helper'

describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:admin) }
  let(:upstream_pipeline) { create(:ci_pipeline) }
  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  context 'custom config content' do
    let(:bridge) do
      create(:ci_bridge, status: 'running', pipeline: upstream_pipeline, project: upstream_pipeline.project).tap do |bridge|
        allow(bridge).to receive(:yaml_for_downstream).and_return(
          <<~YML
            rspec:
              script: rspec
            custom:
              script: custom
          YML
        )
      end
    end

    subject { service.execute(:push, bridge: bridge) }

    it 'creates a pipeline using the content passed in as param' do
      expect(subject).to be_persisted
      expect(subject.builds.map(&:name)).to eq %w[rspec custom]
      expect(subject.config_source).to eq 'bridge_source'
    end
  end
end
