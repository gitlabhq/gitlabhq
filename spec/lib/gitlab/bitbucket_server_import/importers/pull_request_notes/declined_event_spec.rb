# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::DeclinedEvent, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :repository, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }

  let!(:decliner_author) do
    create(:user, username: 'decliner_author', email: 'decliner_author@example.org')
  end

  let(:declined_event) do
    {
      id: 7,
      decliner_username: decliner_author.username,
      decliner_email: decliner_author.email,
      created_at: now
    }
  end

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'imports the declined event' do
      expect { importer.execute(declined_event) }
        .to change { merge_request.events.count }.from(0).to(1)
        .and change { merge_request.resource_state_events.count }.from(0).to(1)

      metrics = merge_request.metrics.reload
      expect(metrics.latest_closed_by).to eq(decliner_author)
      expect(metrics.latest_closed_at).to eq(declined_event[:created_at])

      event = merge_request.events.first
      expect(event.action).to eq('closed')

      resource_state_event = merge_request.resource_state_events.first
      expect(resource_state_event.state).to eq('closed')
    end

    context 'when bitbucket_server_user_mapping_by_username flag is disabled' do
      before do
        stub_feature_flags(bitbucket_server_user_mapping_by_username: false)
      end

      context 'when a user with a matching username does not exist' do
        let(:another_username_event) do
          declined_event.merge(decliner_username: 'another_username')
        end

        it 'finds the user based on email' do
          importer.execute(another_username_event)

          expect(merge_request.metrics.reload.latest_closed_by).to eq(decliner_author)
        end
      end
    end

    context 'when no users match email or username' do
      let(:another_user_event) do
        declined_event.merge(decliner_username: 'another_username', decliner_email: 'another_email@example.org')
      end

      it 'does not set a decliner' do
        expect_log(
          stage: 'import_declined_event',
          message: 'skipped due to missing user',
          iid: merge_request.iid,
          event_id: 7
        )

        expect { importer.execute(another_user_event) }
          .to not_change { merge_request.events.count }
          .and not_change { merge_request.resource_state_events.count }

        expect(merge_request.metrics.reload.latest_closed_by).to be_nil
      end
    end

    it 'logs its progress' do
      expect_log(stage: 'import_declined_event', message: 'starting', iid: merge_request.iid, event_id: 7)
      expect_log(stage: 'import_declined_event', message: 'finished', iid: merge_request.iid, event_id: 7)

      importer.execute(declined_event)
    end
  end
end
