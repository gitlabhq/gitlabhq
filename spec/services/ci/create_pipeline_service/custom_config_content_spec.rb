# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  let(:upstream_pipeline) { create(:ci_pipeline, project: project) }
  let(:bridge) { create(:ci_bridge, pipeline: upstream_pipeline) }

  subject { service.execute(:push, bridge: bridge).payload }

  context 'custom config content' do
    let(:bridge) do
      create(:ci_bridge, status: 'running', pipeline: upstream_pipeline, project: upstream_pipeline.project).tap do |bridge|
        allow(bridge).to receive(:yaml_for_downstream).and_return(config_from_bridge)
      end
    end

    let(:config_from_bridge) do
      <<~YML
        rspec:
          script: rspec
        custom:
          script: custom
      YML
    end

    before do
      allow(bridge).to receive(:yaml_for_downstream).and_return config_from_bridge
    end

    it 'creates a pipeline using the content passed in as param' do
      expect(subject).to be_persisted
      expect(subject.builds.pluck(:name)).to match_array %w[rspec custom]
      expect(subject.config_source).to eq 'bridge_source'
    end

    context 'when bridge includes yaml from artifact' do
      # the generated.yml is available inside the ci_build_artifacts.zip associated
      # to the generator_job
      let(:config_from_bridge) do
        <<~YML
          include:
            - artifact: generated.yml
              job: generator
        YML
      end

      context 'when referenced job exists' do
        let!(:generator_job) do
          create(:ci_build, :artifacts,
            project: project,
            pipeline: upstream_pipeline,
            name: 'generator')
        end

        it 'created a pipeline using the content passed in as param and download the artifact' do
          expect(subject).to be_persisted
          expect(subject.builds.pluck(:name)).to match_array %w[rspec time custom]
          expect(subject.config_source).to eq 'bridge_source'
        end
      end

      context 'when referenced job does not exist' do
        it 'creates an empty pipeline' do
          expect(subject).to be_persisted
          expect(subject).to be_failed
          expect(subject.errors.full_messages)
            .to contain_exactly(
              'Job `generator` not found in parent pipeline or does not have artifacts!')
          expect(subject.builds.pluck(:name)).to be_empty
          expect(subject.config_source).to eq 'bridge_source'
        end
      end
    end
  end
end
