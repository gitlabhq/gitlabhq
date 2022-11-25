# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :yaml_processor_feature_flag_corectness do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service)  { described_class.new(project, user, { ref: 'master' }) }
  let(:pipeline) { service.execute(:push).payload }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  context 'when job has script and nested before_script and after_script' do
    let(:config) do
      <<-CI_CONFIG
      default:
        before_script: echo 'hello default before_script'
        after_script: echo 'hello default after_script'

      job:
        before_script: echo 'hello job before_script'
        after_script: echo 'hello job after_script'
        script: echo 'hello job script'
      CI_CONFIG
    end

    it 'creates a job with script data' do
      expect(pipeline).to be_created_successfully
      expect(pipeline.builds.first).to have_attributes(
        name: 'job',
        stage: 'test',
        options: { script: ["echo 'hello job script'"],
                   before_script: ["echo 'hello job before_script'"],
                   after_script: ["echo 'hello job after_script'"] }
      )
    end
  end

  context 'when job has hooks' do
    let(:config) do
      <<-CI_CONFIG
      job:
        hooks:
          pre_get_sources_script: echo 'hello job pre_get_sources_script'
        script: echo 'hello job script'
      CI_CONFIG
    end

    it 'creates a job with script data' do
      expect(pipeline).to be_created_successfully
      expect(pipeline.builds.first).to have_attributes(
        name: 'job',
        stage: 'test',
        options: { script: ["echo 'hello job script'"],
                   hooks: { pre_get_sources_script: ["echo 'hello job pre_get_sources_script'"] } }
      )
    end
  end
end
