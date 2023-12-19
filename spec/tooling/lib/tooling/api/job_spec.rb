# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/api/job'
require_relative '../../../../../tooling/lib/tooling/api/request'

RSpec.describe Tooling::API::Job, feature_category: :tooling do
  describe '#rspec_failed_files' do
    let(:job) { described_class.new('api_token', 'project_id', 'job_id') }
    let(:failures) { '' }
    let(:log) do
      <<~LOG
        lots of content at the top of the file
        #{failures}
        some content at the bottom of the file
      LOG
    end

    subject(:rspec_failed_files) { job.rspec_failed_files }

    shared_context 'with stubbed API request' do
      before do
        # Stub the API request.
        allow(job).to receive(:get_job_log).and_return(log)
      end
    end

    it 'will fetch job logs' do
      uri = URI("https://gitlab.com/api/v4/projects/project_id/jobs/job_id/trace")

      response_double = instance_double(Net::HTTPOK, body: log)
      expect(Tooling::API::Request).to receive(:get).with('api_token', uri).and_return(response_double)

      rspec_failed_files
    end

    context 'when there are no failures' do
      include_context 'with stubbed API request'

      let(:failures) { '' }

      it { is_expected.to be_empty }
    end

    context 'when a spec fails on a specified line' do
      include_context 'with stubbed API request'

      let(:failures) { 'rspec ./spec/foo_spec.rb:123' }

      it { is_expected.to eq(%w[spec/foo_spec.rb]) }
    end

    context 'when a nested spec fails' do
      include_context 'with stubbed API request'

      let(:failures) { %(rspec './spec/foo_spec.rb[123:456]') }

      it { is_expected.to eq(%w[spec/foo_spec.rb]) }
    end

    context 'when there are multiple spec failures' do
      include_context 'with stubbed API request'

      let(:failures) do
        <<~LOG
          rspec spec/foo_spec.rb:123
          rspec spec/bar_spec.rb:456
          rspec 'spec/ro_spec.rb[1:2]'
          rspec 'spec/sham_spec.rb[3:4]'
          rspec 'spec/bo_spec.rb[5:6]'
        LOG
      end

      it do
        is_expected.to match_array(
          %w[spec/bar_spec.rb spec/bo_spec.rb spec/foo_spec.rb spec/ro_spec.rb spec/sham_spec.rb]
        )
      end
    end

    context 'when there are multiple spec failures in the same file' do
      include_context 'with stubbed API request'

      let(:failures) do
        <<~LOG
          rspec ./spec/foo_spec.rb:123
          rspec ./spec/foo_spec.rb:456
          rspec './spec/bar_spec.rb[1:2]'
          rspec './spec/bar_spec.rb[3:4]'
        LOG
      end

      it { is_expected.to eq(%w[spec/foo_spec.rb spec/bar_spec.rb]) }
    end
  end
end
