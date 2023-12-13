# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/api/pipeline'
require_relative '../../../../../tooling/lib/tooling/api/job'

RSpec.describe Tooling::API::Pipeline, feature_category: :tooling do
  let(:pipeline) { described_class.new('api_token', 'project_id', 'pipeline_id') }

  describe '#failed_jobs' do
    subject { pipeline.failed_jobs }

    context 'when there are failed jobs' do
      let(:jobs) { [{ 'id' => '123' }, { 'id' => '456' }] }
      let(:response) { instance_double(Net::HTTPOK, body: jobs.to_json, '[]' => nil) }

      it 'returns the jobs' do
        allow(Tooling::API::Request).to receive(:get).and_yield(response)

        expect(pipeline.failed_jobs).to eq(jobs)
      end
    end
  end

  describe '#failed_spec_files' do
    let(:job1) { { 'id' => 1 } }
    let(:job2) { { 'id' => 2 } }
    let(:failed_jobs) { [job1, job2] }
    let(:job1_failed_files) { %w[spec/foo_spec.rb spec/bar_spec.rb] }
    let(:job2_failed_files) { %w[spec/baz_spec.rb spec/qux_spec.rb] }
    let(:failed_files) { job1_failed_files + job2_failed_files }

    subject { pipeline.failed_spec_files }

    before do
      allow(pipeline).to receive(:failed_jobs).and_return(failed_jobs)

      allow(Tooling::API::Job).to receive(:new).with(anything, anything, job1['id']).and_return(job1)
      allow(job1).to receive(:rspec_failed_files).and_return(job1_failed_files)

      allow(Tooling::API::Job).to receive(:new).with(anything, anything, job2['id']).and_return(job2)
      allow(job2).to receive(:rspec_failed_files).and_return(job2_failed_files)
    end

    it 'returns the failed spec files' do
      expect(pipeline.failed_spec_files).to match_array(failed_files)
    end

    context 'when Tooling::Debug is enabled' do
      around do |example|
        Tooling::Debug.debug = true
        example.run
      ensure
        Tooling::Debug.debug = false
      end

      it 'outputs the job logs' do
        expect { pipeline.failed_spec_files }.to output(/Fetching failed jobs... found 2/).to_stdout
        expect { pipeline.failed_spec_files }.to output(/Fetching job logs for #1/).to_stdout
        expect { pipeline.failed_spec_files }.to output(/Fetching job logs for #2/).to_stdout
      end
    end
  end
end
