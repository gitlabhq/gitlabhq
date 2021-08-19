# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  describe '.pre/.post stages' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.owner }

    let(:source)   { :push }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    let(:config) do
      <<~YAML
        validate:
          stage: .pre
          script: echo Hello World

        build:
          stage: build
          rules:
            - if: $CI_COMMIT_BRANCH == "master"
          script: echo Hello World

        notify:
          stage: .post
          script: echo Hello World
      YAML
    end

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'when pipeline contains a build except .pre/.post' do
      let(:ref) { 'refs/heads/master' }

      it 'creates a pipeline' do
        expect(pipeline).to be_persisted
        expect(pipeline.stages.map(&:name)).to contain_exactly(
          *%w(.pre build .post))
        expect(pipeline.builds.map(&:name)).to contain_exactly(
          *%w(validate build notify))
      end
    end

    context 'when pipeline does not contain any other build except .pre/.post' do
      let(:ref) { 'refs/heads/feature' }

      it 'does not create a pipeline' do
        expect(pipeline).not_to be_persisted

        # we can validate a list of stages, as they are assigned
        # but not persisted
        expect(pipeline.stages.map(&:name)).to contain_exactly(
          *%w(.pre .post))
      end
    end
  end
end
