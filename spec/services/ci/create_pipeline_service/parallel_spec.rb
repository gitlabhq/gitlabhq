# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

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

      context 'with matrix expressions in needs:parallel:matrix' do
        let(:config) do
          <<-EOY
          .parallel-strat:
            parallel:
              matrix:
                - TARGET: ["linux", "windows"]

          build-job:
            script: echo "Building for $TARGET"
            parallel: !reference [.parallel-strat, parallel]

          test-job:
            script: echo "Testing for $TARGET"
            parallel: !reference [.parallel-strat, parallel]
            needs:
              - job: build-job
                parallel:
                  matrix:
                    - TARGET: $[[ matrix.TARGET ]]
          EOY
        end

        it 'creates pipeline with correct job dependencies' do
          expect(pipeline).to be_created_successfully
          expect(pipeline.processables.count).to eq(4)

          # Check build jobs were created
          build_jobs = pipeline.processables.select { |job| job.name.start_with?('build-job:') }
          expect(build_jobs.count).to eq(2)
          expect(build_jobs.map(&:name)).to match_array([
            'build-job: [linux]',
            'build-job: [windows]'
          ])

          # Check test jobs were created
          test_jobs = pipeline.processables.select { |job| job.name.start_with?('test-job:') }
          expect(test_jobs.count).to eq(2)
          expect(test_jobs.map(&:name)).to match_array([
            'test-job: [linux]',
            'test-job: [windows]'
          ])

          test_linux = find_job('test-job: [linux]')
          test_windows = find_job('test-job: [windows]')

          # Each test job should depend only on the corresponding build job
          expect(test_linux.scheduling_type).to eq('dag')
          expect(test_linux.needs.map(&:name)).to eq(['build-job: [linux]'])

          expect(test_windows.scheduling_type).to eq('dag')
          expect(test_windows.needs.map(&:name)).to eq(['build-job: [windows]'])
        end

        context 'with multi-dimensional matrix' do
          let(:config) do
            <<-EOY
            .matrix_config: &matrix_config
              parallel:
                matrix:
                  - OS: ["ubuntu", "alpine"]
                    ARCH: ["amd64", "arm64"]

            build:
              stage: build
              script: echo "Building $OS-$ARCH"
              <<: *matrix_config

            test:
              stage: test
              script: echo "Testing $OS-$ARCH"
              needs:
                - job: build
                  parallel:
                    matrix:
                      - OS: $[[ matrix.OS ]]
                        ARCH: $[[ matrix.ARCH ]]
              <<: *matrix_config
            EOY
          end

          it 'creates correct dependencies for multi-dimensional matrix' do
            expect(pipeline).to be_created_successfully
            expect(pipeline.processables.count).to eq(8) # 4 build + 4 test jobs

            build_jobs = pipeline.processables.select { |job| job.name.start_with?('build:') }
            test_jobs = pipeline.processables.select { |job| job.name.start_with?('test:') }

            expected_combinations = [
              '[ubuntu, amd64]',
              '[ubuntu, arm64]',
              '[alpine, amd64]',
              '[alpine, arm64]'
            ]

            build_names = build_jobs.map(&:name).map { |n| n.sub('build: ', '') }
            test_names = test_jobs.map(&:name).map { |n| n.sub('test: ', '') }

            expect(build_names).to match_array(expected_combinations)
            expect(test_names).to match_array(expected_combinations)

            # Check that each test job depends on the corresponding build job
            expected_combinations.each do |combination|
              test_job = find_job("test: #{combination}")
              expect(test_job.scheduling_type).to eq('dag')
              expect(test_job.needs.map(&:name)).to eq(["build: #{combination}"])
            end
          end
        end

        context 'with mixed expressions and literal values' do
          let(:config) do
            <<-EOY
            build:
              script: echo "Building $OS-$ENV"
              parallel:
                matrix:
                  - OS: ["linux", "windows"]
                    ENV: ["dev", "prod"]

            integration-test:
              script: echo "Integration test"
              parallel:
                matrix:
                  - OS: ["linux"]
                    ENV: ["prod"]
              needs:
                - job: build
                  parallel:
                    matrix:
                      - OS: $[[ matrix.OS ]]
                        ENV: "prod"
            EOY
          end

          it 'handles mixed matrix expressions and literal values' do
            expect(pipeline).to be_created_successfully

            # Build jobs: 2 OS x 2 ENV = 4 jobs
            build_jobs = pipeline.processables.select { |job| job.name.start_with?('build:') }
            expect(build_jobs.count).to eq(4)

            # Integration test jobs: only 1 combination
            test_jobs = pipeline.processables.select { |job| job.name.start_with?('integration-test:') }
            expect(test_jobs.count).to eq(1)

            test_job = test_jobs.first
            expect(test_job.name).to eq('integration-test: [linux, prod]')

            # Should only depend on the linux+prod build job
            expect(test_job.scheduling_type).to eq('dag')
            expect(test_job.needs.map(&:name)).to contain_exactly('build: [linux, prod]')
          end
        end
      end
    end
  end

  private

  def find_job(name)
    pipeline.processables.find { |job| job.name == name }
  end
end
