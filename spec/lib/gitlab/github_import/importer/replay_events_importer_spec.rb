# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ReplayEventsImporter, feature_category: :importers do
  let_it_be(:association) { create(:merged_merge_request) }
  let_it_be(:project) { association.project }
  let(:user1) { build(:user1) }
  let(:user2) { build(:user2) }
  let(:user3) { build(:user3) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:representation) do
    Gitlab::GithubImport::Representation::ReplayEvent.new(
      issuable_type: association.class.name.to_s, issuable_iid: association.iid
    )
  end

  let(:events) do
    [
      {
        requested_reviewer: { id: 1, login: 'user1' },
        event: 'review_requested'
      },
      {
        requested_reviewer: { id: 1, login: 'user1' },
        event: 'review_request_removed'
      },
      {
        requested_reviewer: { id: 2, login: 'user2' },
        event: 'review_requested'
      },
      {
        requested_reviewer: { id: 2, login: 'user2' },
        event: 'review_request_removed'
      },
      {
        requested_reviewer: { id: 2, login: 'user2' },
        event: 'review_requested'
      },
      {
        requested_reviewer: { id: 3, login: 'user3' },
        event: 'review_requested'
      }
    ]
  end

  subject(:importer) { described_class.new(representation, project, client) }

  describe '#execute' do
    before do
      representations = events.map { |e| Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(e) }

      allow_next_instance_of(Gitlab::GithubImport::EventsCache) do |events_cache|
        allow(events_cache).to receive(:events).with(association).and_return(representations)
      end
    end

    context 'when association is a MergeRequest' do
      it 'imports reviewers' do
        representation = instance_double(Gitlab::GithubImport::Representation::PullRequests::ReviewRequests)

        expect(Gitlab::GithubImport::Representation::PullRequests::ReviewRequests).to receive(:from_json_hash).with(
          merge_request_id: association.id,
          merge_request_iid: association.iid,
          users: [
            { id: 2, login: 'user2' },
            { id: 3, login: 'user3' }
          ]
        ).and_return(representation)

        expect_next_instance_of(
          Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter, anything, project, client
        ) do |review_impoter|
          expect(review_impoter).to receive(:execute)
        end

        importer.execute
      end

      context 'when reviewer is a team' do
        let(:events) do
          [
            {
              event: 'review_requested',
              requested_team: { name: 'backend-team' }
            },
            {
              event: 'review_requested',
              requested_team: { name: 'frontend-team' }
            },
            {
              event: 'review_request_removed',
              requested_team: { name: 'frontend-team' }
            }
          ]
        end

        it 'ignores the events and do not assign the reviewers' do
          expect(Gitlab::GithubImport::Representation::PullRequests::ReviewRequests).to receive(:from_json_hash).with(
            merge_request_id: association.id,
            merge_request_iid: association.iid,
            users: []
          ).and_call_original

          importer.execute
        end
      end
    end

    context 'when association is not found' do
      let(:representation) do
        Gitlab::GithubImport::Representation::ReplayEvent.new(
          issuable_type: association.class.name.to_s, issuable_iid: -1
        )
      end

      it 'does not read events' do
        expect(Gitlab::GithubImport::EventsCache).not_to receive(:new)

        importer.execute
      end
    end

    context 'when issueable type is not supported' do
      let(:representation) do
        Gitlab::GithubImport::Representation::ReplayEvent.new(
          issuable_type: 'Issue', issuable_iid: association.iid
        )
      end

      it 'does not read events' do
        expect(Gitlab::GithubImport::EventsCache).not_to receive(:new)

        importer.execute
      end
    end
  end
end
