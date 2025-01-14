# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::DeclinedEvent, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:declined_event) do
    {
      id: 7,
      decliner_name: 'John Rejections',
      decliner_username: 'decliner_author',
      decliner_email: 'decliner_author@example.org',
      created_at: Time.now.utc.change(usec: 0)
    }
  end

  let_it_be(:source_user) { generate_source_user(project, declined_event[:decliner_username]) }

  def expect_log(stage:, message:, iid:, event_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, event_id: event_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'pushes placeholder references' do
      importer.execute(declined_event)

      cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
      expect(cached_references).to contain_exactly(
        ['Event', instance_of(Integer), 'author_id', source_user.id],
        ['MergeRequest::Metrics', instance_of(Integer), 'latest_closed_by_id', source_user.id]
      )
    end

    it 'imports the declined event' do
      expect { importer.execute(declined_event) }
        .to change { merge_request.events.count }.from(0).to(1)
        .and change { merge_request.resource_state_events.count }.from(0).to(1)

      metrics = merge_request.metrics.reload
      expect(metrics.latest_closed_by_id).to eq(source_user.mapped_user_id)
      expect(metrics.latest_closed_at).to eq(declined_event[:created_at])

      event = merge_request.events.first
      expect(event.author_id).to eq(source_user.mapped_user_id)
      expect(event.action).to eq('closed')

      resource_state_event = merge_request.resource_state_events.first
      expect(resource_state_event.state).to eq('closed')
    end

    it 'logs its progress' do
      expect_log(stage: 'import_declined_event', message: 'starting', iid: merge_request.iid, event_id: 7)
      expect_log(stage: 'import_declined_event', message: 'finished', iid: merge_request.iid, event_id: 7)

      importer.execute(declined_event)
    end

    context 'when declined event has no associated user' do
      let(:declined_event) { super().merge(decliner_username: nil) }

      it 'does not set a decliner' do
        expect_log(
          stage: 'import_declined_event',
          message: 'skipped due to missing user',
          iid: merge_request.iid,
          event_id: 7
        )

        expect { importer.execute(declined_event) }
          .to not_change { merge_request.events.count }
          .and not_change { merge_request.resource_state_events.count }

        expect(merge_request.metrics.reload.latest_closed_by).to be_nil
      end
    end

    context 'when user contribution mapping is disabled' do
      let_it_be(:decliner_author) { create(:user, username: 'decliner_author', email: 'decliner_author@example.org') }

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'finds the user based on email' do
        importer.execute(declined_event)

        expect(merge_request.metrics.reload.latest_closed_by).to eq(decliner_author)
      end

      it 'does not push placeholder references' do
        importer.execute(declined_event)

        cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
        expect(cached_references).to be_empty
      end

      context 'when no users match email' do
        let(:another_user_event) { declined_event.merge(decliner_email: 'another_email@example.org') }

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
    end
  end
end
