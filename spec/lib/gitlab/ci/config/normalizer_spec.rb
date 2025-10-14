# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Normalizer, feature_category: :pipeline_composition do
  let(:job_name) { :rspec }
  let(:job_config) { { script: 'rspec', parallel: parallel_config, name: 'rspec', job_variables: variables_config } }
  let(:config) { { job_name => job_config } }

  describe '.normalize_jobs' do
    subject(:normalized_jobs) { described_class.new(config).normalize_jobs }

    shared_examples 'parallel dependencies' do
      context "when job has dependencies on parallelized jobs" do
        let(:config) do
          {
            job_name => job_config,
            other_job: { script: 'echo 1', dependencies: [job_name.to_s] }
          }
        end

        it "parallelizes dependencies" do
          expect(subject[:other_job][:dependencies]).to eq(expanded_job_names)
        end

        it "does not include original job name in #{context}" do
          expect(subject[:other_job][:dependencies]).not_to include(job_name)
        end
      end

      context "when there are dependencies which are both parallelized and not" do
        let(:config) do
          {
            job_name => job_config,
            other_job: { script: 'echo 1' },
            final_job: { script: 'echo 1', dependencies: [job_name.to_s, "other_job"] }
          }
        end

        it "parallelizes dependencies" do
          expect(subject[:final_job][:dependencies]).to include(*expanded_job_names)
        end

        it "includes the regular job in dependencies" do
          expect(subject[:final_job][:dependencies]).to include('other_job')
        end
      end
    end

    shared_examples 'parallel needs' do
      let(:expanded_job_attributes) do
        expanded_job_names.map do |job_name|
          { name: job_name, extra: :key }
        end
      end

      context 'when job has needs on parallelized jobs' do
        let(:config) do
          {
            job_name => job_config,
            other_job: {
              script: 'echo 1',
              needs: {
                job: [
                  { name: job_name.to_s, extra: :key }
                ]
              }
            }
          }
        end

        it 'parallelizes needs' do
          expect(subject.dig(:other_job, :needs, :job)).to eq(expanded_job_attributes)
        end
      end

      context 'when there are dependencies which are both parallelized and not' do
        let(:config) do
          {
            job_name => job_config,
            other_job: {
              script: 'echo 1'
            },
            final_job: {
              script: 'echo 1',
              needs: {
                job: [
                  { name: job_name.to_s, extra: :key },
                  { name: 'other_job', extra: :key }
                ]
              }
            }
          }
        end

        it 'parallelizes dependencies' do
          expect(subject.dig(:final_job, :needs, :job)).to include(*expanded_job_attributes)
        end

        it 'includes the regular job in dependencies' do
          expect(subject.dig(:final_job, :needs, :job)).to include(name: 'other_job', extra: :key)
        end
      end
    end

    shared_examples 'needs:parallel:matrix' do
      let(:expanded_needs_parallel_job_attributes) do
        expanded_needs_parallel_job_names.map do |job_name|
          { name: job_name }
        end
      end

      context 'when job has needs:parallel:matrix on parallelized jobs' do
        let(:config) do
          {
            job_name => job_config,
            other_job: {
              script: 'echo 1',
              needs: {
                job: [
                  { name: job_name.to_s, parallel: needs_parallel_config }
                ]
              }
            }
          }
        end

        it 'parallelizes and only keeps needs specified by needs:parallel:matrix' do
          expect(subject.dig(:other_job, :needs, :job)).to eq(expanded_needs_parallel_job_attributes)
        end
      end
    end

    context 'with parallel config as integer' do
      let(:variables_config) { {} }
      let(:parallel_config) { 5 }

      let(:expanded_job_names) do
        [
          'rspec 1/5',
          'rspec 2/5',
          'rspec 3/5',
          'rspec 4/5',
          'rspec 5/5'
        ]
      end

      it 'does not have original job' do
        is_expected.not_to include(job_name)
      end

      it 'has parallelized jobs' do
        is_expected.to include(*expanded_job_names.map(&:to_sym))
      end

      it 'sets job instance in options' do
        expect(subject.values).to all(include(:instance))
      end

      it 'parallelizes jobs with original config' do
        original_config = config[job_name]
          .except(:name)
          .deep_merge(parallel: { total: parallel_config })

        configs = subject.values.map { |config| config.except(:name, :instance) }

        expect(configs).to all(eq(original_config))
      end

      context 'when the job is not parallelized' do
        let(:job_config) { { script: 'rspec', name: 'rspec' } }

        it 'returns the same hash' do
          is_expected.to eq(config)
        end
      end

      context 'when there is a job with a slash in it' do
        let(:job_name) { :"rspec 35/2" }

        it 'properly parallelizes job names' do
          job_names = [
            :"rspec 35/2 1/5",
            :"rspec 35/2 2/5",
            :"rspec 35/2 3/5",
            :"rspec 35/2 4/5",
            :"rspec 35/2 5/5"
          ]

          is_expected.to include(*job_names)
        end
      end

      it_behaves_like 'parallel dependencies'
      it_behaves_like 'parallel needs'
    end

    context 'with a simple parallel matrix config' do
      let(:variables_config) do
        {
          USER_VARIABLE: 'user value'
        }
      end

      let(:parallel_config) do
        {
          matrix: [
            {
              VAR_1: ['A'],
              VAR_2: %w[B C]
            }
          ]
        }
      end

      let(:expanded_job_names) do
        [
          'rspec: [A, B]',
          'rspec: [A, C]'
        ]
      end

      let(:needs_parallel_config) do
        {
          matrix: [
            {
              VAR_1: ['A'],
              VAR_2: ['C']
            }
          ]
        }
      end

      let(:expanded_needs_parallel_job_names) { ['rspec: [A, C]'] }

      it 'does not have original job' do
        is_expected.not_to include(job_name)
      end

      it 'sets job instance in options' do
        expect(subject.values).to all(include(:instance))
      end

      it 'sets job variables', :aggregate_failures do
        expect(subject.values[0]).to match(
          a_hash_including(job_variables: { VAR_1: 'A', VAR_2: 'B', USER_VARIABLE: 'user value' })
        )

        expect(subject.values[1]).to match(
          a_hash_including(job_variables: { VAR_1: 'A', VAR_2: 'C', USER_VARIABLE: 'user value' })
        )
      end

      it 'parallelizes jobs with original config' do
        configs = subject.values.map do |config|
          config.except(:name, :instance, :job_variables)
        end

        original_config = config[job_name]
          .except(:name, :job_variables)
          .deep_merge(parallel: { total: 2 })

        expect(configs).to all(match(a_hash_including(original_config)))
      end

      it 'has parallelized jobs' do
        is_expected.to include(*expanded_job_names.map(&:to_sym))
      end

      it_behaves_like 'parallel dependencies'
      it_behaves_like 'parallel needs'
      it_behaves_like 'needs:parallel:matrix'
    end

    context 'with a complex parallel matrix config' do
      let(:variables_config) { {} }
      let(:parallel_config) do
        {
          matrix: [
            {
              PLATFORM: ['centos'],
              STACK: %w[ruby python java],
              DB: %w[postgresql mysql]
            },
            {
              PLATFORM: ['ubuntu'],
              PROVIDER: %w[aws gcp]
            }
          ]
        }
      end

      let(:needs_parallel_config) do
        {
          matrix: [
            {
              PLATFORM: ['centos'],
              STACK: %w[ruby python],
              DB: ['postgresql']
            },
            {
              PLATFORM: ['ubuntu'],
              PROVIDER: ['aws']
            }
          ]
        }
      end

      let(:expanded_needs_parallel_job_names) do
        [
          'rspec: [centos, ruby, postgresql]',
          'rspec: [centos, python, postgresql]',
          'rspec: [ubuntu, aws]'
        ]
      end

      let(:expanded_job_names) do
        [
          'rspec: [centos, ruby, postgresql]',
          'rspec: [centos, ruby, mysql]',
          'rspec: [centos, python, postgresql]',
          'rspec: [centos, python, mysql]',
          'rspec: [centos, java, postgresql]',
          'rspec: [centos, java, mysql]',
          'rspec: [ubuntu, aws]',
          'rspec: [ubuntu, gcp]'
        ]
      end

      it_behaves_like 'parallel needs'
      it_behaves_like 'needs:parallel:matrix'
    end

    context 'when parallel config does not matches a factory' do
      let(:variables_config) { {} }
      let(:parallel_config) {}

      it 'does not alter the job config' do
        is_expected.to match(config)
      end
    end

    context 'when jobs config is nil' do
      let(:config) { nil }

      it { is_expected.to eq({}) }
    end

    context 'with matrix expressions in needs configuration' do
      let(:build_job_config) do
        {
          script: 'echo build',
          parallel: {
            matrix: [
              { 'OS' => ['linux'], 'ARCH' => %w[amd64 arm64] }
            ]
          }
        }
      end

      let(:test_job_config) do
        {
          script: 'echo test',
          parallel: {
            matrix: [
              { 'OS' => ['linux'], 'ARCH' => %w[amd64 arm64] }
            ]
          },
          needs: {
            job: [
              {
                name: 'build',
                parallel: {
                  matrix: [
                    { 'OS' => ['$[[ matrix.OS ]]'], 'ARCH' => ['$[[ matrix.ARCH ]]'] }
                  ]
                }
              }
            ]
          }
        }
      end

      let(:config) do
        {
          build: build_job_config,
          test: test_job_config
        }
      end

      subject(:normalized_jobs) do
        # Remove with_actor wrapper when ci_matrix_expressions FF is removed
        Gitlab::Ci::Config::FeatureFlags.with_actor(nil) do
          described_class.new(config).normalize_jobs
        end
      end

      it 'interpolates matrix expressions in needs configuration' do
        result = subject

        # Should have 2 build jobs and 2 test jobs (linux + amd64/arm64)
        expect(result.keys.map(&:to_s)).to include(
          'build: [linux, amd64]', 'build: [linux, arm64]',
          'test: [linux, amd64]', 'test: [linux, arm64]'
        )

        test_amd64 = result[:'test: [linux, amd64]']
        test_arm64 = result[:'test: [linux, arm64]']

        expect(test_amd64[:needs]).to eq({
          job: [
            { name: 'build: [linux, amd64]' }
          ]
        })

        expect(test_arm64[:needs]).to eq({
          job: [
            { name: 'build: [linux, arm64]' }
          ]
        })
      end

      context 'with missing matrix variables' do
        let(:test_job_config) do
          {
            script: 'echo test',
            parallel: {
              matrix: [
                { 'OS' => ['linux'], 'ARCH' => %w[amd64 arm64] }
              ]
            },
            needs: {
              job: [
                {
                  name: 'build',
                  parallel: {
                    matrix: [
                      { 'OS' => ['$[[ matrix.OS ]]'], 'MISSING' => ['$[[ matrix.NONEXISTENT ]]'] }
                    ]
                  }
                }
              ]
            }
          }
        end

        it 'collects errors for missing matrix variables and leaves config unchanged' do
          normalizer = described_class.new(config)

          # Remove with_actor wrapper when ci_matrix_expressions FF is removed
          normalized_jobs = Gitlab::Ci::Config::FeatureFlags.with_actor(nil) do
            normalizer.normalize_jobs
          end

          test_job = normalized_jobs[:'test: [linux, amd64]']

          expect(test_job[:needs][:job][0][:name]).to eq('build: [$[[ matrix.OS ]], $[[ matrix.NONEXISTENT ]]]')
          expect(normalizer.errors).to contain_exactly(
            "test job: 'NONEXISTENT' does not exist in matrix configuration"
          )
        end
      end

      context 'when ci_matrix_expressions feature flag is disabled' do
        before do
          stub_feature_flags(ci_matrix_expressions: false)
        end

        it 'does not interpolate matrix expressions' do
          expect(normalized_jobs.keys.map(&:to_s)).to contain_exactly(
            'build: [linux, amd64]', 'build: [linux, arm64]',
            'test: [linux, amd64]', 'test: [linux, arm64]'
          )

          test_amd64 = normalized_jobs[:'test: [linux, amd64]']
          test_arm64 = normalized_jobs[:'test: [linux, arm64]']

          expect(test_amd64[:needs]).to eq({
            job: [
              { name: 'build: [$[[ matrix.OS ]], $[[ matrix.ARCH ]]]' }
            ]
          })

          expect(test_arm64[:needs]).to eq({
            job: [
              { name: 'build: [$[[ matrix.OS ]], $[[ matrix.ARCH ]]]' }
            ]
          })
        end
      end
    end
  end
end
