# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.owner }

  let(:service)  { described_class.new(project, user, { ref: 'master' }) }
  let(:pipeline) { service.execute(:push).payload }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  context 'job:parallel' do
    context 'numeric' do
      let(:config) do
        <<-EOY
        job:
          script: "echo job"
          parallel: 3
        EOY
      end

      it 'creates the pipeline' do
        expect(pipeline).to be_created_successfully
      end

      it 'creates 3 jobs' do
        expect(pipeline.processables.pluck(:name)).to contain_exactly(
          'job 1/3', 'job 2/3', 'job 3/3'
        )
      end
    end

    context 'matrix' do
      let(:config) do
        <<-EOY
        job:
          script: "echo job"
          parallel:
            matrix:
              - PROVIDER: ovh
                STACK: [monitoring, app]
              - PROVIDER: [gcp, vultr]
                STACK: [data]
        EOY
      end

      it 'creates the pipeline' do
        expect(pipeline).to be_created_successfully
      end

      it 'creates 4 builds with the corresponding matrix variables' do
        expect(pipeline.processables.pluck(:name)).to contain_exactly(
          'job: [gcp, data]', 'job: [ovh, app]', 'job: [ovh, monitoring]', 'job: [vultr, data]'
        )

        job1 = find_job('job: [gcp, data]')
        job2 = find_job('job: [ovh, app]')
        job3 = find_job('job: [ovh, monitoring]')
        job4 = find_job('job: [vultr, data]')

        expect(job1.scoped_variables.to_hash).to include('PROVIDER' => 'gcp', 'STACK' => 'data')
        expect(job2.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'app')
        expect(job3.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'monitoring')
        expect(job4.scoped_variables.to_hash).to include('PROVIDER' => 'vultr', 'STACK' => 'data')
      end

      context 'when a bridge is using parallel:matrix' do
        let(:config) do
          <<-EOY
          job:
            stage: test
            script: "echo job"

          deploy:
            stage: deploy
            trigger:
              include: child.yml
            parallel:
              matrix:
                - PROVIDER: ovh
                  STACK: [monitoring, app]
                - PROVIDER: [gcp, vultr]
                  STACK: [data]
          EOY
        end

        it 'creates the pipeline' do
          expect(pipeline).to be_created_successfully
        end

        it 'creates 1 build and 4 bridges with the corresponding matrix variables' do
          expect(pipeline.processables.pluck(:name)).to contain_exactly(
            'job', 'deploy: [gcp, data]', 'deploy: [ovh, app]', 'deploy: [ovh, monitoring]', 'deploy: [vultr, data]'
          )

          bridge1 = find_job('deploy: [gcp, data]')
          bridge2 = find_job('deploy: [ovh, app]')
          bridge3 = find_job('deploy: [ovh, monitoring]')
          bridge4 = find_job('deploy: [vultr, data]')

          expect(bridge1.scoped_variables.to_hash).to include('PROVIDER' => 'gcp', 'STACK' => 'data')
          expect(bridge2.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'app')
          expect(bridge3.scoped_variables.to_hash).to include('PROVIDER' => 'ovh', 'STACK' => 'monitoring')
          expect(bridge4.scoped_variables.to_hash).to include('PROVIDER' => 'vultr', 'STACK' => 'data')
        end
      end
    end
  end

  private

  def find_job(name)
    pipeline.processables.find { |job| job.name == name }
  end
end
