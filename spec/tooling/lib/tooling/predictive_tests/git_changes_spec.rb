# frozen_string_literal: true

require "gitlab_quality/test_tooling"

require_relative "../../../../../tooling/lib/tooling/predictive_tests/git_changes"

RSpec.describe Tooling::PredictiveTests::GitChanges, :silence_stdout, feature_category: :tooling do
  subject(:changes) do
    described_class.new(
      base_sha: 'base', clickhouse_client: clickhouse_client, project_path: 'gitlab-org/gitlab', git: git
    )
  end

  let(:clickhouse_client) do
    instance_double(GitlabQuality::TestTooling::ClickHouse::Client, query: rows)
  end

  let(:git) { instance_double(Proc) }
  let(:rows) { [{ 'sha' => 'capture' }] }

  describe '#since_last_capture' do
    context 'when the capture is newer than the MR base' do
      before do
        allow(git).to receive(:call).with('cat-file', any_args)
        allow(git).to receive(:call).with('show', '-s', '--format=%ct', 'capture').and_return("300\n")
        allow(git).to receive(:call).with('show', '-s', '--format=%ct', 'base').and_return("200\n")
      end

      it 'lists nothing' do
        expect(changes.since_last_capture).to eq([])
      end
    end

    context 'when git fails' do
      before do
        allow(git).to receive(:call).and_raise(RuntimeError, 'boom')
      end

      it 'returns nil' do
        expect(changes.since_last_capture).to be_nil
      end
    end

    context 'when the map has no capture' do
      let(:rows) { [] }

      it 'returns nil' do
        expect(changes.since_last_capture).to be_nil
      end
    end
  end
end
