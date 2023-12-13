# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :yaml_processor_feature_flag_corectness,
  feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service)  { described_class.new(project, user, { ref: 'master' }) }
  let(:pipeline) { service.execute(:push).payload }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  describe 'on_new_commit' do
    context 'when is set to interruptible' do
      let(:config) do
        <<~YAML
          workflow:
            auto_cancel:
              on_new_commit: interruptible

          test1:
            script: exit 0
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline with on_new_commit' do
        expect(pipeline).to be_persisted
        expect(pipeline.errors).to be_empty
        expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
      end
    end

    context 'when is set to invalid' do
      let(:config) do
        <<~YAML
          workflow:
            auto_cancel:
              on_new_commit: invalid

          test1:
            script: exit 0
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline with errors' do
        expect(pipeline).to be_persisted
        expect(pipeline.errors.full_messages).to include(
          'workflow:auto_cancel on new commit must be one of: conservative, interruptible, disabled')
      end
    end
  end

  describe 'on_job_failure' do
    context 'when is set to none' do
      let(:config) do
        <<~YAML
          workflow:
            auto_cancel:
              on_job_failure: none

          test1:
            script: exit 0
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline with on_job_failure' do
        expect(pipeline).to be_persisted
        expect(pipeline.errors).to be_empty
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
      end
    end

    context 'when is set to all' do
      let(:config) do
        <<~YAML
          workflow:
            auto_cancel:
              on_job_failure: all

          test1:
            script: exit 0
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline with on_job_failure' do
        expect(pipeline).to be_persisted
        expect(pipeline.errors).to be_empty
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
      end

      context 'when auto_cancel_pipeline_on_job_failure feature flag is disabled' do
        before do
          stub_feature_flags(auto_cancel_pipeline_on_job_failure: false)
        end

        context 'when there are no other metadata settings present' do
          it 'creates a pipeline without metadata' do
            expect(pipeline).to be_persisted
            expect(pipeline.errors).to be_empty
            expect(pipeline.pipeline_metadata).to be_nil
          end
        end

        context 'when other metadata settings are present' do
          let(:config) do
            <<~YAML
              workflow:
                name: pipeline_name
                auto_cancel:
                  on_job_failure: all

              test1:
                script: exit 0
            YAML
          end

          it 'creates a pipeline with on_job_failure' do
            expect(pipeline).to be_persisted
            expect(pipeline.errors).to be_empty
            expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
          end
        end
      end
    end

    context 'when on_job_failure is set to invalid' do
      let(:config) do
        <<~YAML
          workflow:
            auto_cancel:
              on_job_failure: invalid

          test1:
            script: exit 0
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a pipeline with errors' do
        expect(pipeline).to be_persisted
        expect(pipeline.errors.full_messages).to include(
          'workflow:auto_cancel on job failure must be one of: none, all')
      end
    end
  end
end
