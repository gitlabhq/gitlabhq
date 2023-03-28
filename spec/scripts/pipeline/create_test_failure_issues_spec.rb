# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require 'active_support/testing/time_helpers'
require 'rspec-parameterized'

require_relative '../../../scripts/pipeline/create_test_failure_issues'

RSpec.describe CreateTestFailureIssues, feature_category: :tooling do
  describe CreateTestFailureIssue do
    include ActiveSupport::Testing::TimeHelpers

    let(:env) do
      {
        'CI_JOB_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/jobs/1234',
        'CI_PIPELINE_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/pipelines/5678'
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
        'job_url' => env['CI_JOB_URL']
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

    let(:test_id) { Digest::SHA256.hexdigest(failed_test['file'] + failed_test['name'])[0...12] }
    let(:latest_format_issue_title) { "#{failed_test['file']} [test-hash:#{test_id}]" }

    around do |example|
      freeze_time { example.run }
    end

    before do
      stub_env(env)
      allow(creator).to receive(:puts)
    end

    describe '#upsert' do
      let(:expected_search_payload) do
        {
          state: :opened,
          search: test_id,
          in: :title,
          per_page: 1
        }
      end

      let(:find_issue_stub) { double('FindIssues') }
      let(:issue_stub) { double('Issue', title: latest_format_issue_title, web_url: 'issue_web_url') }

      before do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(File.expand_path(File.join('..', '..', '..', test_file), __dir__))
          .and_return(test_file_stub)
        allow(creator).to receive(:categories_mapping).and_return(categories_mapping)
        allow(creator).to receive(:groups_mapping).and_return(groups_mapping)
      end

      context 'when no issues are found' do
        let(:expected_description) do
          <<~DESCRIPTION
          ### Test description

          `#{failed_test['name']}`

          ### Test file path

          [`#{failed_test['file']}`](https://gitlab.com/example/gitlab/-/blob/master/#{failed_test['file']})

          <!-- Don't add anything after the report list since it's updated automatically -->
          ### Reports (1)

          1. #{Time.new.utc.strftime('%F')}: #{failed_test['job_url']} (#{env['CI_PIPELINE_URL']})
          DESCRIPTION
        end

        let(:create_issue_stub) { double('CreateIssue') }

        let(:expected_create_payload) do
          {
            title: latest_format_issue_title,
            description: expected_description,
            labels: described_class::DEFAULT_LABELS.map { |label| "wip-#{label}" } + [
              "wip-#{categories_mapping['source_code_management']['label']}",
              "wip-#{groups_mapping['source_code']['label']}"
            ],
            weight: 1
          }
        end

        before do
          allow(FindIssues).to receive(:new).with(project: project, api_token: api_token).and_return(find_issue_stub)
          allow(find_issue_stub).to receive(:execute).with(expected_search_payload).and_return([])
        end

        it 'calls CreateIssue#execute(payload)' do
          stub_const("#{described_class}::FILE_BASE_URL", 'https://gitlab.com/example/gitlab/-/blob/master/')

          expect(CreateIssue).to receive(:new).with(project: project, api_token: api_token)
            .and_return(create_issue_stub)

          expect(create_issue_stub).to receive(:execute).with(expected_create_payload).and_return(issue_stub)

          creator.upsert(failed_test)
        end
      end

      context 'when issues are found' do
        let(:failed_test_report_line) do
          "1. #{Time.new.utc.strftime('%F')}: #{failed_test['job_url']} (#{env['CI_PIPELINE_URL']})"
        end

        let(:latest_format_issue_description) do
          <<~DESCRIPTION
          ### Test description

          `#{failed_test['name']}`

          ### Test file path

          [`#{failed_test['file']}`](https://gitlab.com/example/gitlab/-/blob/master/#{failed_test['file']})

          <!-- Don't add anything after the report list since it's updated automatically -->
          ### Reports (1)

          #{failed_test_report_line}
          DESCRIPTION
        end

        let(:issue_stub) do
          double('Issue', iid: 42, title: issue_title, description: issue_description, web_url: 'issue_web_url')
        end

        let(:update_issue_stub) do
          double('UpdateIssue', description: latest_format_issue_description)
        end

        let(:expected_update_payload) do
          {
            description: latest_format_issue_description.sub(/^### Reports.*$/, '### Reports (2)') +
              "\n#{failed_test_report_line}",
            weight: 2
          }
        end

        before do
          allow(FindIssues).to receive(:new).with(project: project, api_token: api_token).and_return(find_issue_stub)
          allow(find_issue_stub).to receive(:execute).with(expected_search_payload).and_return([issue_stub])
        end

        # This shared example can be useful if we want to test migration to a new format in the future
        shared_examples 'existing issue update' do
          it 'calls UpdateIssue#execute(payload)' do
            expect(UpdateIssue).to receive(:new).with(project: project, api_token: api_token)
              .and_return(update_issue_stub)
            expect(update_issue_stub).to receive(:execute).with(42, **expected_update_payload).and_return(issue_stub)

            creator.upsert(failed_test)
          end
        end

        context 'when issue already has the latest format' do
          let(:issue_description) { latest_format_issue_description }
          let(:issue_title) { latest_format_issue_title }

          it_behaves_like 'existing issue update'
        end
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
