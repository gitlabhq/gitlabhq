# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::Normalizer do
  let(:job_name) { :rspec }
  let(:job_config) { { script: 'rspec', parallel: 5, name: 'rspec' } }
  let(:config) { { job_name => job_config } }

  describe '.normalize_jobs' do
    subject { described_class.new(config).normalize_jobs }

    it 'does not have original job' do
      is_expected.not_to include(job_name)
    end

    it 'has parallelized jobs' do
      job_names = [:"rspec 1/5", :"rspec 2/5", :"rspec 3/5", :"rspec 4/5", :"rspec 5/5"]

      is_expected.to include(*job_names)
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
        job_names = [:"rspec 35/2 1/5", :"rspec 35/2 2/5", :"rspec 35/2 3/5", :"rspec 35/2 4/5", :"rspec 35/2 5/5"]

        is_expected.to include(*job_names)
      end
    end

    %i[dependencies needs].each do |context|
      context "when job has #{context} on parallelized jobs" do
        let(:config) do
          {
            job_name => job_config,
            other_job: { script: 'echo 1', context => [job_name.to_s] }
          }
        end

        it "parallelizes #{context}" do
          job_names = ["rspec 1/5", "rspec 2/5", "rspec 3/5", "rspec 4/5", "rspec 5/5"]

          expect(subject[:other_job][context]).to include(*job_names)
        end

        it "does not include original job name in #{context}" do
          expect(subject[:other_job][context]).not_to include(job_name)
        end
      end

      context "when there are #{context} which are both parallelized and not" do
        let(:config) do
          {
            job_name => job_config,
            other_job: { script: 'echo 1' },
            final_job: { script: 'echo 1', context => [job_name.to_s, "other_job"] }
          }
        end

        it "parallelizes #{context}" do
          job_names = ["rspec 1/5", "rspec 2/5", "rspec 3/5", "rspec 4/5", "rspec 5/5"]

          expect(subject[:final_job][context]).to include(*job_names)
        end

        it "includes the regular job in #{context}" do
          expect(subject[:final_job][context]).to include('other_job')
        end
      end
    end
  end
end
