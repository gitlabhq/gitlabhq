# frozen_string_literal: true

require 'spec_helper'
require './keeps/overdue_finalize_background_migration'

MigrationRecord = Struct.new(:id, :finished_at, :updated_at, :gitlab_schema)

RSpec.describe Keeps::OverdueFinalizeBackgroundMigration, feature_category: :tooling do
  subject(:keep) { described_class.new }

  describe '#initialize_change_details' do
    let(:migration) { { 'feature_category' => 'shared', 'introduced_by_url' => introduced_by_url } }
    let(:feature_category) { migration['feature_category'] }
    let(:introduced_by_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:groups_helper) { instance_double(::Keeps::Helpers::Groups) }
    let(:reviewer_roulette) { instance_double(::Keeps::Helpers::ReviewerRoulette) }
    let(:identifiers) { [described_class.new.class.name.demodulize, job_name] }

    subject(:change) do
      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = identifiers
      keep.send(:initialize_change_details, change, migration, migration_record, job_name, last_migration_file)
      change
    end

    before do
      allow(groups_helper).to receive(:labels_for_feature_category)
        .with(feature_category)
        .and_return([])

      allow(reviewer_roulette).to receive(:random_reviewer_for)
        .with('maintainer::database', identifiers: identifiers)
        .and_return("random-engineer")

      allow(Keeps::Helpers::Groups).to receive(:instance).and_return(groups_helper)
      allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(reviewer_roulette)
      allow(keep).to receive(:assignees_from_introduced_by_mr)
                       .with(introduced_by_url)
                       .and_return(['original-author'])
    end

    it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
      expect(change).to be_a(::Gitlab::Housekeeper::Change)
      expect(change.title).to eq("Finalize BBM #{job_name}")
      expect(change.identifiers).to eq(identifiers)
      expect(change.labels).to eq(['maintenance::removal'])
      expect(change.reviewers).to eq(['random-engineer'])
      expect(change.assignees).to eq(['original-author'])
    end
  end

  describe '#change_description' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:chatops_command) { %r{/chatops run batched_background_migrations status \d+ --database main} }

    subject(:description) { keep.change_description(migration_record, job_name, last_migration_file) }

    context 'when migration code is present' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(true)
      end

      it 'does not contain a warning' do
        expect(description).not_to match(/^### Warning/)
      end

      it 'contains the database name' do
        expect(description).to match(chatops_command)
      end
    end

    context 'when migration code is absent' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(false)
      end

      it 'does contain a warning' do
        expect(description).to match(/^### Warning/)
      end
    end
  end

  describe '#truncate_migration_name' do
    let(:migration_name) { 'FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationNameThatIsLongerThanLimit' }

    subject(:truncated_name) { keep.truncate_migration_name(migration_name) }

    it 'returns truncated name' do
      expect(truncated_name).to eq('FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationName51841')
    end

    context 'when name is short enough' do
      let(:migration_name) { 'FinalizeHKSomeShortMigrationName' }

      it 'returns the name' do
        expect(truncated_name).to eq(migration_name)
      end
    end
  end

  describe '#should_push_code?' do
    using RSpec::Parameterized::TableSyntax

    let(:change) { instance_double(::Gitlab::Housekeeper::Change) }
    let(:outdated_migration_checker) do
      instance_double(Keeps::OverdueFinalizeBackgroundMigrations::OutdatedMigrationChecker)
    end

    before do
      allow(change).to receive(:identifiers).and_return(%w[OverdueFinalizeBackgroundMigration TestMigration])
      allow(keep).to receive(:outdated_migration_checker).and_return(outdated_migration_checker)
    end

    where(:already_approved, :push_when_approved, :code_update_required, :timestamp_outdated, :expected_result) do
      # When timestamp is outdated, always push regardless of other conditions
      true  | false | false | true | true
      true  | false | true  | true | true
      false | false | false | true | true

      # When timestamp is not outdated, fall back to base Keep behavior
      true  | false | true  | false | false
      true  | false | false | false | false
      true  | true  | true  | false | true
      true  | true  | false | false | false
      false | false | true  | false | true
      false | false | false | false | false
    end

    with_them do
      it 'determines if we should push' do
        allow(change).to receive(:already_approved?).and_return(already_approved)
        allow(change).to receive(:update_required?).with(:code).and_return(code_update_required)
        allow(outdated_migration_checker).to receive(:existing_migration_timestamp_outdated?)
                                         .with(change.identifiers).and_return(timestamp_outdated)

        expect(keep.should_push_code?(change, push_when_approved)).to eq(expected_result)
      end
    end
  end

  describe '#outdated_migration_checker' do
    it 'returns an OutdatedMigrationChecker instance' do
      expect(keep.outdated_migration_checker)
        .to be_a(Keeps::OverdueFinalizeBackgroundMigrations::OutdatedMigrationChecker)
    end

    it 'memoizes the checker' do
      checker = keep.outdated_migration_checker
      expect(keep.outdated_migration_checker).to be(checker)
    end
  end

  describe '#database_name' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: gitlab_schema)
    end

    subject(:database_name) { keep.database_name(migration_record) }

    context 'when schema is gitlab_main_cell' do
      let(:gitlab_schema) { 'gitlab_main_cell' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when schema is gitlab_main_org' do
      let(:gitlab_schema) { 'gitlab_main_org' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when schema is gitlab_main' do
      let(:gitlab_schema) { 'gitlab_main' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when using multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'when schema is gitlab_ci' do
        let(:gitlab_schema) { 'gitlab_ci' }

        it 'returns the database name' do
          expect(database_name).to eq('ci')
        end
      end
    end
  end

  describe '#assignees_from_introduced_by_mr' do
    subject(:assignees) { keep.send(:assignees_from_introduced_by_mr, introduced_by_url) }

    context 'when introduced_by_url is nil' do
      let(:introduced_by_url) { nil }

      it 'returns nil' do
        expect(assignees).to be_nil
      end
    end

    context 'when introduced_by_url is present' do
      let(:introduced_by_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
      let(:merge_request_response) do
        {
          assignees: [
            { username: 'user1' },
            { username: 'user2' }
          ]
        }
      end

      before do
        allow(keep).to receive(:get_merge_request)
                         .with(introduced_by_url)
                         .and_return(merge_request_response)
      end

      it 'returns the assignee usernames' do
        expect(assignees).to eq(%w[user1 user2])
      end

      context 'when merge request has no assignees' do
        let(:merge_request_response) { { assignees: nil } }

        it 'returns nil' do
          expect(assignees).to be_nil
        end
      end

      context 'when get_merge_request returns nil' do
        before do
          allow(keep).to receive(:get_merge_request)
                           .with(introduced_by_url)
                           .and_return(nil)
        end

        it 'returns nil' do
          expect(assignees).to be_nil
        end
      end
    end
  end

  describe '#get_merge_request' do
    subject(:merge_request) { keep.send(:get_merge_request, merge_request_url) }

    context 'when URL does not match the expected pattern' do
      let(:merge_request_url) { 'https://example.com/invalid/url' }

      it 'returns nil' do
        expect(merge_request).to be_nil
      end
    end

    context 'when URL matches the expected pattern' do
      let(:merge_request_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
      let(:api_url) { 'https://gitlab.com/api/v4/projects/278964/merge_requests/12345' }
      let(:response_body) do
        {
          id: 12345,
          iid: 12345,
          assignees: [{ username: 'user1' }]
        }.to_json
      end

      let(:response) { instance_double(HTTParty::Response, success?: true, body: response_body) }

      before do
        allow(Gitlab::HTTP_V2).to receive(:try_get)
                                    .with(api_url)
                                    .and_return(response)
      end

      it 'returns the parsed merge request data' do
        expect(merge_request).to eq({
          id: 12345,
          iid: 12345,
          assignees: [{ username: 'user1' }]
        })
      end

      context 'when the API request fails' do
        let(:response) { instance_double(HTTParty::Response, success?: false, code: 404, body: 'Not found') }

        it 'returns nil' do
          expect(merge_request).to be_nil
        end
      end
    end
  end
end
