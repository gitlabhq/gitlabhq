# frozen_string_literal: true

require 'rspec-parameterized'
require "gitlab_quality/test_tooling"

require_relative "../../../../../tooling/lib/tooling/predictive_tests/file_based_selector"

RSpec.describe Tooling::PredictiveTests::FileBasedSelector, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  subject(:result) do
    described_class.new(
      changed_files: changed_files,
      recent_changed_files: recent_changed_files,
      clickhouse_client: clickhouse_client,
      project_path: 'gitlab-org/gitlab',
      file_exists: ->(path) { existing_files.include?(path) }
    ).execute
  end

  let(:clickhouse_client) { instance_double(GitlabQuality::TestTooling::ClickHouse::Client) }
  let(:rows) { [] }
  let(:recent_changed_files) { [] }
  let(:existing_files) { rows.map { |row| row['test_file'] } + changed_files }
  let(:map_age) { 3600 }

  before do
    allow(clickhouse_client).to receive(:query).with(/dateDiff/, any_args).and_return([{ 'age' => map_age }])
    allow(clickhouse_client).to receive(:query).with(/test_files_by_source_file/, any_args).and_return(rows)
  end

  context 'when the newest capture is older than 6 hours' do
    let(:changed_files) { %w[app/models/user.rb] }
    let(:map_age) { 7 * 3600 }

    it 'asks for the full suite' do
      expect(result.full_suite_reason).to include('map is stale: newest capture is 7 hours old')
      expect(result.specs).to be_empty
    end
  end

  context 'when the MR also changes a spec file' do
    let(:changed_files) { %w[app/models/user.rb spec/models/user_spec.rb spec/models/other_spec.rb] }
    let(:rows) { [{ 'source_file' => 'app/models/user.rb', 'test_file' => 'spec/models/user_spec.rb' }] }

    it 'adds the changed spec once, even when the map does not list it' do
      expect(result.specs).to eq(%w[spec/models/other_spec.rb spec/models/user_spec.rb])
    end
  end

  context 'when a spec from the map was deleted' do
    let(:changed_files) { %w[app/models/user.rb] }
    let(:rows) do
      [
        { 'source_file' => 'app/models/user.rb', 'test_file' => 'spec/models/user_spec.rb' },
        { 'source_file' => 'app/models/user.rb', 'test_file' => 'spec/models/gone_spec.rb' }
      ]
    end

    let(:existing_files) { %w[spec/models/user_spec.rb] }

    it 'drops the deleted spec' do
      expect(result.specs).to eq(%w[spec/models/user_spec.rb])
    end
  end

  context 'when a changed source file has map rows and the map is fresh' do
    let(:changed_files) { %w[app/models/user.rb] }
    let(:rows) { [{ 'source_file' => 'app/models/user.rb', 'test_file' => 'spec/models/user_spec.rb' }] }

    it 'selects the specs from the map' do
      expect(result.full_suite_reason).to be_nil
      expect(result.specs).to eq(%w[spec/models/user_spec.rb])
    end
  end

  context 'when only frontend files change' do
    let(:changed_files) { %w[app/assets/javascripts/a.vue spec/frontend/a_spec.js] }

    it 'selects nothing and does not ask for the full suite' do
      expect(result.specs).to be_empty
      expect(result.full_suite_reason).to be_nil
      expect(clickhouse_client).not_to have_received(:query)
    end
  end

  context 'when a Vue 3 migration file changes' do
    where(:changed_file) do
      %w[
        app/assets/javascripts/pages/projects/jobs/show/vue3_migration.yml
        app/assets/javascripts/sentry/vue3_migration.yml
        ee/app/assets/javascripts/pages/foo/bar/index.js
      ]
    end

    with_them do
      let(:changed_files) { [changed_file] }

      it 'asks for the full suite' do
        expect(result.full_suite_reason).to include(changed_file)
      end
    end
  end

  context 'when a file the map cannot judge changes' do
    let(:changed_files) { %w[app/models/user.rb Gemfile.lock] }

    it 'asks for the full suite' do
      expect(result.full_suite_reason).to include('Gemfile.lock')
    end
  end

  context 'when a source file has no map rows' do
    let(:changed_files) { %w[app/models/new_thing.rb] }

    it 'asks for the full suite' do
      expect(result.full_suite_reason).to include('app/models/new_thing.rb')
    end
  end

  context 'when master changed after the last capture' do
    let(:changed_files) { %w[app/models/user.rb] }
    let(:rows) do
      [{ 'source_file' => 'app/models/user.rb', 'test_file' => 'spec/models/user_spec.rb' }]
    end

    let(:recent_changed_files) do
      %w[spec/models/new_spec.rb app/models/recent.rb app/assets/javascripts/a.vue]
    end

    let(:existing_files) { %w[spec/models/user_spec.rb spec/models/new_spec.rb] }

    it 'adds the specs changed on master' do
      expect(result.specs).to eq(%w[spec/models/new_spec.rb spec/models/user_spec.rb])
      expect(clickhouse_client).to have_received(:query).with(/test_files_by_source_file/, any_args).once
    end

    context 'when more than 500 specs changed' do
      let(:recent_changed_files) { Array.new(501) { |i| "spec/models/s#{i}_spec.rb" } }

      it 'asks for the full suite' do
        expect(result.full_suite_reason).to include('501 specs changed since the last capture')
      end
    end

    context 'when the last capture is unknown' do
      let(:recent_changed_files) { nil }

      it 'asks for the full suite' do
        expect(result.full_suite_reason).to include("can't tell what changed since the last capture")
      end
    end
  end

  context 'when the MR only changes a spec and the last capture is unknown' do
    let(:changed_files) { %w[spec/models/user_spec.rb] }
    let(:recent_changed_files) { nil }

    it 'selects the spec without asking for the full suite' do
      expect(result.full_suite_reason).to be_nil
      expect(result.specs).to eq(%w[spec/models/user_spec.rb])
    end
  end
end
