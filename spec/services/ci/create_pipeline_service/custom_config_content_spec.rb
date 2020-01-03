# frozen_string_literal: true
require 'spec_helper'

describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:admin) }
  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  context 'custom config content' do
    let(:bridge) do
      double(:bridge, yaml_for_downstream: <<~YML
        rspec:
          script: rspec
        custom:
          script: custom
      YML
      )
    end

    subject { service.execute(:push, bridge: bridge) }

    it 'creates a pipeline using the content passed in as param' do
      expect(subject).to be_persisted
      expect(subject.builds.map(&:name)).to eq %w[rspec custom]
      expect(subject.config_source).to eq 'bridge_source'
    end
  end
end
