# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/diff_stats_exporter'
require 'fast_spec_helper'

RSpec.describe Tooling::DiffStatsExporter, feature_category: :tooling do
  include StubENV

  let(:exporter) { described_class.new(log_level: :error) }

  let(:required_env) do
    {
      'GLCI_DA_CLICKHOUSE_URL' => 'https://clickhouse.example.com',
      'GLCI_CLICKHOUSE_METRICS_USERNAME' => 'user',
      'GLCI_CLICKHOUSE_METRICS_PASSWORD' => 'pass',
      'GLCI_CLICKHOUSE_WORK_ITEM_DB' => 'work_item_metrics',
      'GLCI_DIFF_STATS_CLICKHOUSE_TABLE' => 'commit_metrics',
      'CI_COMMIT_SHA' => 'abc123def456',
      'CI_PIPELINE_ID' => '99',
      'CI_PROJECT_ID' => '278964',
      'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
      'CI_MERGE_REQUEST_IID' => '42',
      'CI_MERGE_REQUEST_EVENT_TYPE' => 'merged_result',
      'CI_MERGE_REQUEST_DIFF_BASE_SHA' => 'base123sha456',
      'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => 'source123sha789',
      'CI_COMMIT_REF_NAME' => 'my-feature-branch',
      'CI_SERVER_HOST' => 'gitlab.com'
    }
  end

  let(:numstat_output) do
    <<~OUTPUT
      10\t3\tapp/models/user.rb
      25\t0\tspec/models/user_spec.rb
      -\t-\tsome_binary.png
    OUTPUT
  end

  let(:name_status_output) do
    <<~OUTPUT
      M\tapp/models/user.rb
      A\tspec/models/user_spec.rb
      M\tsome_binary.png
    OUTPUT
  end

  let(:git_log_output) { "Fix user model|||John Doe|||john@example.com|||2026-01-16T05:50:00+00:00" }

  before do
    stub_env(required_env)

    allow(Open3).to receive(:capture2e).with("git", "fetch", "origin", "base123sha456", "--depth=1")
      .and_return(["", instance_double(Process::Status, success?: true)])

    allow(Open3).to receive(:capture2e).with("git", "diff", "--numstat", "base123sha456..source123sha789")
      .and_return([numstat_output, instance_double(Process::Status, success?: true)])

    allow(Open3).to receive(:capture2e).with("git", "diff", "--name-status", "base123sha456..source123sha789")
      .and_return([name_status_output, instance_double(Process::Status, success?: true)])

    allow(Open3).to receive(:capture2e).with("git", "log", "-1", "source123sha789",
      "--format=#{described_class::GIT_LOG_FORMAT}")
      .and_return([git_log_output, instance_double(Process::Status, success?: true)])
  end

  describe '#execute' do
    let(:clickhouse_client) { instance_double(GitlabQuality::TestTooling::ClickHouse::Client) }

    before do
      allow(GitlabQuality::TestTooling::ClickHouse::Client).to receive(:new).and_return(clickhouse_client)
      allow(clickhouse_client).to receive(:insert_json_data)
    end

    it 'inserts a row into ClickHouse with correct data' do
      exporter.execute

      expect(clickhouse_client).to have_received(:insert_json_data).with(
        'commit_metrics',
        [hash_including(
          commit_sha: 'abc123def456',
          project_id: 278964,
          project_path: 'gitlab-org/gitlab',
          pipeline_id: 99,
          mr_iid: 42,
          ref: 'my-feature-branch',
          message: 'Fix user model',
          author_name: 'John Doe',
          author_email: 'john@example.com',
          committed_at: '2026-01-16T05:50:00+00:00',
          total_lines_added: 35,
          total_lines_deleted: 3,
          total_files_changed: 2,
          gitlab_instance: 'gitlab.com'
        )]
      )
    end

    it 'includes correct changed_files data' do
      exporter.execute

      expect(clickhouse_client).to have_received(:insert_json_data).with(
        'commit_metrics',
        [hash_including(
          changed_files: [
            { path: 'app/models/user.rb', change_type: 'modified', file_extension: '.rb', lines_added: 10,
              lines_deleted: 3 },
            { path: 'spec/models/user_spec.rb', change_type: 'added', file_extension: '.rb', lines_added: 25,
              lines_deleted: 0 }
          ]
        )]
      )
    end

    it 'skips binary files (lines shown as -)' do
      exporter.execute

      expect(clickhouse_client).to have_received(:insert_json_data).with(
        'commit_metrics',
        [hash_including(total_files_changed: 2)]
      )
    end

    it 'returns true on success' do
      expect(exporter.execute).to be(true)
    end

    context 'when a required env var is missing' do
      before do
        stub_env('CI_MERGE_REQUEST_IID' => '')
      end

      it 'returns false and does not insert data' do
        expect(exporter.execute).to be(false)
        expect(clickhouse_client).not_to have_received(:insert_json_data)
      end
    end

    shared_examples 'returns false on git failure' do |description, *command|
      context "when #{description}" do
        before do
          allow(Open3).to receive(:capture2e).with(*command)
            .and_return(["fatal: error", instance_double(Process::Status, success?: false)])
        end

        it 'returns false' do
          expect(exporter.execute).to be(false)
        end
      end
    end

    include_examples 'returns false on git failure', 'git fetch fails',
      "git", "fetch", "origin", "base123sha456", "--depth=1"

    include_examples 'returns false on git failure', 'git diff --numstat fails',
      "git", "diff", "--numstat", "base123sha456..source123sha789"

    include_examples 'returns false on git failure', 'git diff --name-status fails',
      "git", "diff", "--name-status", "base123sha456..source123sha789"

    include_examples 'returns false on git failure', 'git log fails',
      "git", "log", "-1", "source123sha789", "--format=#{Tooling::DiffStatsExporter::GIT_LOG_FORMAT}"

    context 'in a merged_result pipeline' do
      it 'uses CI_MERGE_REQUEST_SOURCE_BRANCH_SHA for diff and git log' do
        exporter.execute

        expect(Open3).to have_received(:capture2e).with("git", "diff", "--numstat", "base123sha456..source123sha789")
        expect(Open3).to have_received(:capture2e).with("git", "log", "-1", "source123sha789",
          "--format=#{described_class::GIT_LOG_FORMAT}")
      end
    end

    context 'in a detached MR pipeline' do
      before do
        stub_env(
          'CI_MERGE_REQUEST_EVENT_TYPE' => 'detached',
          'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => ''
        )

        allow(Open3).to receive(:capture2e).with("git", "fetch", "origin", "base123sha456", "--depth=1")
          .and_return(["", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture2e).with("git", "diff", "--numstat", "base123sha456..abc123def456")
          .and_return([numstat_output, instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture2e).with("git", "diff", "--name-status", "base123sha456..abc123def456")
          .and_return([name_status_output, instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture2e).with("git", "log", "-1", "abc123def456",
          "--format=#{described_class::GIT_LOG_FORMAT}")
          .and_return([git_log_output, instance_double(Process::Status, success?: true)])
      end

      it 'uses CI_COMMIT_SHA as the source SHA for diff and git log' do
        expect(exporter.execute).to be(true)
        expect(Open3).to have_received(:capture2e).with("git", "diff", "--numstat", "base123sha456..abc123def456")
        expect(Open3).to have_received(:capture2e).with("git", "log", "-1", "abc123def456",
          "--format=#{described_class::GIT_LOG_FORMAT}")
      end
    end

    context 'when error has no backtrace' do
      before do
        allow(clickhouse_client).to receive(:insert_json_data).and_raise(StandardError.new("no backtrace"))
        allow_next_instance_of(StandardError) do |instance|
          allow(instance).to receive(:backtrace).and_return(nil)
        end
      end

      it 'returns false without raising' do
        expect(exporter.execute).to be(false)
      end
    end

    context 'when ClickHouse insert fails' do
      before do
        allow(clickhouse_client).to receive(:insert_json_data).and_raise(StandardError, "connection refused")
      end

      it 'returns false' do
        expect(exporter.execute).to be(false)
      end
    end

    context 'with a renamed file' do
      let(:name_status_output) do
        <<~OUTPUT
          R100\tlib/old_name.rb\tlib/new_name.rb
        OUTPUT
      end

      let(:numstat_output) do
        <<~OUTPUT
          5\t2\tlib/new_name.rb
        OUTPUT
      end

      it 'maps renamed files correctly' do
        exporter.execute

        expect(clickhouse_client).to have_received(:insert_json_data).with(
          'commit_metrics',
          [hash_including(
            changed_files: [
              { path: 'lib/new_name.rb', change_type: 'renamed', file_extension: '.rb', lines_added: 5,
                lines_deleted: 2 }
            ]
          )]
        )
      end
    end

    context 'with no changed files' do
      let(:numstat_output) { "" }
      let(:name_status_output) { "" }

      it 'exports a row with empty changed_files' do
        exporter.execute

        expect(clickhouse_client).to have_received(:insert_json_data).with(
          'commit_metrics',
          [hash_including(changed_files: [], total_files_changed: 0)]
        )
      end
    end

    context 'with malformed numstat lines (fewer than 3 tab-separated parts)' do
      let(:numstat_output) do
        <<~OUTPUT
          10\t3\tapp/models/user.rb
          malformed-line
        OUTPUT
      end

      let(:name_status_output) do
        <<~OUTPUT
          M\tapp/models/user.rb
        OUTPUT
      end

      it 'skips malformed lines and processes valid ones' do
        exporter.execute

        expect(clickhouse_client).to have_received(:insert_json_data).with(
          'commit_metrics',
          [hash_including(total_files_changed: 1)]
        )
      end
    end

    context 'with empty lines in name_status output' do
      let(:name_status_output) do
        "M\tapp/models/user.rb\n\nA\tspec/models/user_spec.rb\n"
      end

      it 'skips empty lines and processes valid ones' do
        exporter.execute

        expect(clickhouse_client).to have_received(:insert_json_data).with(
          'commit_metrics',
          [hash_including(total_files_changed: 2)]
        )
      end
    end
  end

  describe 'GIT_STATUS_MAP' do
    it 'maps all expected git status codes' do
      expect(described_class::GIT_STATUS_MAP).to include(
        "A" => "added",
        "M" => "modified",
        "D" => "deleted",
        "R" => "renamed",
        "C" => "copied"
      )
    end
  end
end
