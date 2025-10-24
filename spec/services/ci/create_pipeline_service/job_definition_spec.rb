# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service)  { described_class.new(project, user, { ref: 'master' }) }
  let(:pipeline) { service.execute(:push, content: config).payload }

  context 'when there are jobs with different definitions' do
    let(:config) do
      <<-YAML
      rspec1:
        script: rspec 1
        parallel: 2

      rspec2:
        script: rspec 2

      lint1:
        script: lint 1
        variables:
          ABC: XYZ
        parallel: 2

      lint2:
        script: lint 2
        interruptible: true

      with_id_tokens:
        script: hello 1
        id_tokens:
          TEST_ID_TOKEN:
            aud: 'https://gitlab.com'
      YAML
    end

    let(:rspec11)        { find_job('rspec1 1/2') }
    let(:rspec12)        { find_job('rspec1 2/2') }
    let(:rspec2)         { find_job('rspec2') }
    let(:lint11)         { find_job('lint1 1/2') }
    let(:lint12)         { find_job('lint1 2/2') }
    let(:lint2)          { find_job('lint2') }
    let(:with_id_tokens) { find_job('with_id_tokens') }

    it 'creates job definition for each unique job' do
      expect do
        expect(pipeline).to be_created_successfully
      end.to change { ::Ci::JobDefinition.count }.by(7)
         .and change { ::Ci::JobDefinitionInstance.count }.by(7)

      expect(rspec11.job_definition.config[:options][:script]).to eq(['rspec 1'])
      expect(rspec2.job_definition.config[:options][:script]).to eq(['rspec 2'])
      expect(lint11.job_definition.config[:options][:script]).to eq(['lint 1'])
      expect(lint2.job_definition.config[:options][:script]).to eq(['lint 2'])
      expect(with_id_tokens.job_definition.config[:options][:script]).to eq(['hello 1'])
    end

    it 'avoids creating duplicate job definitions' do
      # creating the first pipeline
      service.execute(:push, content: config).payload

      # creating the second pipeline
      expect do
        expect do
          expect(pipeline).to be_created_successfully
        end.not_to change { ::Ci::JobDefinition.count }
      end.to change { ::Ci::JobDefinitionInstance.count }.by(7)
    end

    it 'does not save metadata for jobs' do
      pipeline.processables.each do |job|
        expect(job.metadata).to be_nil
      end
    end
  end

  context 'when there are jobs with run steps' do
    let(:config) do
      <<-YAML
      with_run1:
        run:
          - name: step1
            script: echo "step 1"

      with_run2:
        run:
          - name: step2
            script: echo "step 2"

      duplicate_run1:
        run:
          - name: step1
            script: echo "step 1"

      regular_script:
        script: echo "regular script"
      YAML
    end

    let(:with_run1)     { find_job('with_run1') }
    let(:with_run2)     { find_job('with_run2') }
    let(:duplicate_run1) { find_job('duplicate_run1') }
    let(:regular_script) { find_job('regular_script') }

    it 'creates job definition for each unique job' do
      expect do
        expect(pipeline).to be_created_successfully
      end.to change { ::Ci::JobDefinition.count }.by(3)
         .and change { ::Ci::JobDefinitionInstance.count }.by(4)

      expect(with_run1.job_definition.config[:run_steps]).to eq([{ name: 'step1', script: 'echo "step 1"' }])
      expect(with_run2.job_definition.config[:run_steps]).to eq([{ name: 'step2', script: 'echo "step 2"' }])
      expect(duplicate_run1.job_definition.config[:run_steps]).to eq(
        [{ name: 'step1', script: 'echo "step 1"' }]
      )
    end

    it 'avoids creating duplicate job definitions' do
      # creating the first pipeline
      service.execute(:push, content: config).payload

      # creating the second pipeline
      expect do
        expect do
          expect(pipeline).to be_created_successfully
        end.not_to change { ::Ci::JobDefinition.count }
      end.to change { ::Ci::JobDefinitionInstance.count }.by(4)
    end
  end

  private

  def find_job(name)
    pipeline.processables.find { |job| job.name == name }
  end
end
