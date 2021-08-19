# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  describe '!reference tags' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.owner }

    let(:ref) { 'refs/heads/master' }
    let(:source) { :push }
    let(:service) { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'with valid config' do
      let(:config) do
        <<~YAML
        .job-1:
          script:
            - echo doing step 1 of job 1

        .job-2:
          before_script:
            - ls
          script: !reference [.job-1, script]

        job:
          before_script: !reference [.job-2, before_script]
          script:
            - echo doing my first step
            - !reference [.job-2, script]
            - echo doing my last step
        YAML
      end

      it 'creates a pipeline' do
        expect(pipeline).to be_persisted
        expect(pipeline.builds.first.options).to match(a_hash_including({
          before_script: ['ls'],
          script: [
            'echo doing my first step',
            'echo doing step 1 of job 1',
            'echo doing my last step'
          ]
        }))
      end
    end

    context 'with invalid config' do
      let(:config) do
        <<~YAML
        job-1:
          script:
            - echo doing step 1 of job 1
            - !reference [job-3, script]

        job-2:
          script:
            - echo doing step 1 of job 2
            - !reference [job-3, script]

        job-3:
          script:
            - echo doing step 1 of job 3
            - !reference [job-1, script]
        YAML
      end

      it 'creates a pipeline without builds' do
        expect(pipeline).to be_persisted
        expect(pipeline.builds).to be_empty
        expect(pipeline.yaml_errors).to eq("!reference [\"job-3\", \"script\"] is part of a circular chain")
      end
    end
  end
end
