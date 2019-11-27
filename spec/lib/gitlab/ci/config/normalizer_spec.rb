# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::Normalizer do
  let(:job_name) { :rspec }
  let(:job_config) { { script: 'rspec', parallel: 5, name: 'rspec' } }
  let(:config) { { job_name => job_config } }

  let(:expanded_job_names) do
    [
      "rspec 1/5",
      "rspec 2/5",
      "rspec 3/5",
      "rspec 4/5",
      "rspec 5/5"
    ]
  end

  describe '.normalize_jobs' do
    subject { described_class.new(config).normalize_jobs }

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
      original_config = config[job_name].except(:name)
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

    context 'for dependencies' do
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
          job_names = ["rspec 1/5", "rspec 2/5", "rspec 3/5", "rspec 4/5", "rspec 5/5"]

          expect(subject[:final_job][:dependencies]).to include(*job_names)
        end

        it "includes the regular job in dependencies" do
          expect(subject[:final_job][:dependencies]).to include('other_job')
        end
      end
    end

    context 'for needs' do
      let(:expanded_job_attributes) do
        expanded_job_names.map do |job_name|
          { name: job_name, extra: :key }
        end
      end

      context "when job has needs on parallelized jobs" do
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

        it "parallelizes needs" do
          expect(subject.dig(:other_job, :needs, :job)).to eq(expanded_job_attributes)
        end
      end

      context "when there are dependencies which are both parallelized and not" do
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
                  { name: "other_job", extra: :key }
                ]
              }
            }
          }
        end

        it "parallelizes dependencies" do
          expect(subject.dig(:final_job, :needs, :job)).to include(*expanded_job_attributes)
        end

        it "includes the regular job in dependencies" do
          expect(subject.dig(:final_job, :needs, :job)).to include(name: 'other_job', extra: :key)
        end
      end
    end
  end
end
