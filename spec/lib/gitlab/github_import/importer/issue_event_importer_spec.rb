# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::IssueEventImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:importer) { described_class.new(issue_event, project, client) }

  let(:project) { build(:project) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => 1, 'login' => 'alice' },
      'event' => event_name,
      'commit_id' => '570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
      'commit_url' =>
        'https://api.github.com/repos/octocat/Hello-World/commits/570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
      'created_at' => '2022-04-26 18:30:53 UTC',
      'performed_via_github_app' => nil
    )
  end

  let(:event_name) { 'closed' }

  shared_examples 'triggers specific event importer' do |importer_class|
    it importer_class.name do
      expect_next_instance_of(importer_class, project, client) do |importer|
        expect(importer).to receive(:execute).with(issue_event)
      end

      importer.execute
    end
  end

  describe '#execute' do
    context "when it's closed issue event" do
      let(:event_name) { 'closed' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Closed
    end

    context "when it's reopened issue event" do
      let(:event_name) { 'reopened' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Reopened
    end

    context "when it's labeled issue event" do
      let(:event_name) { 'labeled' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedLabel
    end

    context "when it's unlabeled issue event" do
      let(:event_name) { 'unlabeled' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedLabel
    end

    context "when it's renamed issue event" do
      let(:event_name) { 'renamed' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Renamed
    end

    context "when it's milestoned issue event" do
      let(:event_name) { 'milestoned' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedMilestone
    end

    context "when it's demilestoned issue event" do
      let(:event_name) { 'demilestoned' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedMilestone
    end

    context "when it's cross-referenced issue event" do
      let(:event_name) { 'cross-referenced' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::CrossReferenced
    end

    context "when it's assigned issue event" do
      let(:event_name) { 'assigned' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedAssignee
    end

    context "when it's unassigned issue event" do
      let(:event_name) { 'unassigned' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedAssignee
    end

    context "when it's review_requested issue event" do
      let(:event_name) { 'review_requested' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedReviewer
    end

    context "when it's review_request_removed issue event" do
      let(:event_name) { 'review_request_removed' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::ChangedReviewer
    end

    context "when it's merged issue event" do
      let(:event_name) { 'merged' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Merged
    end

    context "when it's commented issue event" do
      let(:event_name) { 'commented' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Commented
    end

    context "when it's reviewed issue event" do
      let(:event_name) { 'reviewed' }

      it_behaves_like 'triggers specific event importer', Gitlab::GithubImport::Importer::Events::Reviewed
    end

    context "when it's unknown issue event" do
      let(:event_name) { 'fake' }

      it 'logs warning and skips' do
        expect(Gitlab::GithubImport::Logger).to receive(:debug)
          .with(
            message: 'UNSUPPORTED_EVENT_TYPE',
            event_type: issue_event.event,
            event_github_id: issue_event.id
          )

        importer.execute
      end
    end
  end
end
