# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../scripts/pipeline/create_test_failure_issues'

RSpec.describe CreateTestFailureIssues, feature_category: :tooling do
  describe CreateTestFailureIssue do
    let(:env) do
      {
        'CI_JOB_URL' => 'ci_job_url',
        'CI_PIPELINE_URL' => 'ci_pipeline_url'
      }
    end

    let(:project) { 'group/project' }
    let(:api_token) { 'api_token' }
    let(:creator) { described_class.new(project: project, api_token: api_token) }
    let(:test_name) { 'The test description' }
    let(:test_file) { 'spec/path/to/file_spec.rb' }
    let(:test_file_content) do
      <<~CONTENT
      # comment

      RSpec.describe Foo, feature_category: :source_code_management do
      end

      CONTENT
    end

    let(:test_file_stub) { double(read: test_file_content) }
    let(:failed_test) do
      {
        'name' => test_name,
        'file' => test_file,
        'job_url' => 'job_url'
      }
    end

    let(:categories_mapping) do
      {
        'source_code_management' => {
          'group' => 'source_code',
          'label' => 'Category:Source Code Management'
        }
      }
    end

    let(:groups_mapping) do
      {
        'source_code' => {
          'label' => 'group::source_code'
        }
      }
    end

    before do
      stub_env(env)
    end

    describe '#find' do
      let(:expected_payload) do
        {
          state: 'opened',
          search: "#{failed_test['file']} - ID: #{Digest::SHA256.hexdigest(failed_test['name'])[0...12]}"
        }
      end

      let(:find_issue_stub) { double('FindIssues') }
      let(:issue_stub) { double(title: expected_payload[:title], web_url: 'issue_web_url') }

      before do
        allow(creator).to receive(:puts)
      end

      it 'calls FindIssues#execute(payload)' do
        expect(FindIssues).to receive(:new).with(project: project, api_token: api_token).and_return(find_issue_stub)
        expect(find_issue_stub).to receive(:execute).with(expected_payload).and_return([issue_stub])

        creator.find(failed_test)
      end

      context 'when no issues are found' do
        it 'calls FindIssues#execute(payload)' do
          expect(FindIssues).to receive(:new).with(project: project, api_token: api_token).and_return(find_issue_stub)
          expect(find_issue_stub).to receive(:execute).with(expected_payload).and_return([])

          creator.find(failed_test)
        end
      end
    end

    describe '#create' do
      let(:expected_description) do
        <<~DESCRIPTION
        ### Full description

        `#{failed_test['name']}`

        ### File path

        `#{failed_test['file']}`

        <!-- Don't add anything after the report list since it's updated automatically -->
        ### Reports

        - #{failed_test['job_url']} (#{env['CI_PIPELINE_URL']})
        DESCRIPTION
      end

      let(:expected_payload) do
        {
          title: "#{failed_test['file']} - ID: #{Digest::SHA256.hexdigest(failed_test['name'])[0...12]}",
          description: expected_description,
          labels: described_class::DEFAULT_LABELS.map { |label| "wip-#{label}" } + [
            "wip-#{categories_mapping['source_code_management']['label']}", "wip-#{groups_mapping['source_code']['label']}" # rubocop:disable Layout/LineLength
          ]
        }
      end

      let(:create_issue_stub) { double('CreateIssue') }
      let(:issue_stub) { double(title: expected_payload[:title], web_url: 'issue_web_url') }

      before do
        allow(creator).to receive(:puts)
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(File.expand_path(File.join('..', '..', '..', test_file), __dir__))
          .and_return(test_file_stub)
        allow(creator).to receive(:categories_mapping).and_return(categories_mapping)
        allow(creator).to receive(:groups_mapping).and_return(groups_mapping)
      end

      it 'calls CreateIssue#execute(payload)' do
        expect(CreateIssue).to receive(:new).with(project: project, api_token: api_token).and_return(create_issue_stub)
        expect(create_issue_stub).to receive(:execute).with(expected_payload).and_return(issue_stub)

        creator.create(failed_test) # rubocop:disable Rails/SaveBang
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
