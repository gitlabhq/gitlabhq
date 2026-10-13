# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::IssuesPipeline, feature_category: :importers do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:group, freeze: false) { create(:group, owners: user) }
  let_it_be(:project, freeze: false) { create(:project, group: group) }
  let_it_be(:bulk_import, freeze: false) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity, freeze: false) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker, freeze: false) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context, freeze: false) { BulkImports::Pipeline::Context.new(tracker) }

  let_it_be(:source_user, freeze: false) do
    create(:import_source_user,
      import_type: ::Import::SOURCE_DIRECT_TRANSFER,
      namespace: group,
      source_user_identifier: 101,
      source_hostname: bulk_import.configuration.url,
      placeholder_user: create(:user, :import_user)
    )
  end

  let(:minimal_issue) do
    {
      title: 'Imported issue',
      author_id: 101,
      iid: 38,
      state: 'opened'
    }
  end

  let(:issue) do
    {
      title: 'Imported issue',
      author_id: 101,
      iid: 38,
      updated_by_id: 101,
      last_edited_at: '2019-12-27T00:00:00.000Z',
      last_edited_by_id: 101,
      closed_by_id: 101,
      state: 'opened',
      events: [{ author_id: 101, action: 'closed', target_type: 'Issue' }],
      timelogs: [{ time_spent: 72000, spent_at: '2019-12-27T00:00:00.000Z', user_id: 101 }],
      notes: [
        {
          note: 'Note',
          noteable_type: 'Issue',
          author_id: 101,
          updated_by_id: 101,
          resolved_by_id: 101,
          events: [{ action: 'created', author_id: 101 }],
          system_note_metadata: { commit_count: nil, action: "cross_reference" }
        }
      ],
      resource_label_events: [{ action: 'add', user_id: 101, label: { title: 'Ambalt', color: '#33594f' } }],
      resource_milestone_events: [{ user_id: 101, action: 'add', state: 'opened', milestone: { title: 'Sprint 1' } }],
      resource_state_events: [{ user_id: 101, state: 'closed' }],
      designs: [{ filename: 'design.png', iid: 101 }],
      design_versions: [{
        sha: '0ec80e1499f275d0553a2831608dd6938672eb44',
        author_id: 101,
        actions: [{ event: 'creation', design: { filename: 'design.png', iid: 1 } }]
      }],
      issue_assignees: [{ user_id: 101 }],
      award_emoji: [{ name: 'clapper', user_id: 101 }]
    }.deep_stringify_keys
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      issue_with_index = [issue, 0]

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [issue_with_index]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)
      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original
    end

    it 'imports issues and maps user references to placeholder users', :aggregate_failures do
      pipeline.run

      issue = project.issues.last
      event = issue.events.first
      note = issue.notes.first
      note_event = note.events.first
      timelog = issue.timelogs.first
      resource_label_event = issue.resource_label_events.first
      resource_milestone_event = issue.resource_milestone_events.first
      resource_state_events = issue.resource_state_events.first
      design_version = issue.design_versions.first
      issue_assignee = issue.issue_assignees.first
      award_emoji = issue.award_emoji.first

      expect(issue.author).to be_import_user
      expect(issue.updated_by).to be_import_user
      expect(issue.last_edited_by).to be_import_user
      expect(issue.closed_by).to be_import_user
      expect(event.author).to be_import_user
      expect(timelog.user).to be_import_user
      expect(timelog.time_spent).to eq(72000)
      expect(note.author).to be_import_user
      expect(note.updated_by).to be_import_user
      expect(note.resolved_by).to be_import_user
      expect(note_event.author).to be_import_user
      expect(resource_label_event.user).to be_import_user
      expect(resource_milestone_event.user).to be_import_user
      expect(resource_state_events.user).to be_import_user
      expect(design_version.author).to be_import_user
      expect(issue_assignee.assignee).to be_import_user
      expect(award_emoji.user).to be_import_user

      source_user = Import::SourceUser.find_by(source_user_identifier: 101)
      expect(source_user.placeholder_user).to be_import_user

      expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(16).times
    end

    context 'when an issue with the same IID exists' do
      let!(:existing_issue) { create(:issue, project: project, iid: issue['iid'], description: 'old description') }

      it 'deletes the existing record and imports a new record' do
        expect { pipeline.run }.to change { Issue.exists?(existing_issue.id) }.from(true).to(false)

        new_record = project.issues.last
        expect(project.issues.count).to eq(1)
        expect(new_record.iid).to eq(issue['iid'])
      end
    end

    context 'zoom meetings' do
      let(:issue) { minimal_issue.merge(zoom_meetings: [{ url: 'https://zoom.us/j/123456789' }]).deep_stringify_keys }

      it 'restores zoom meetings' do
        pipeline.run

        expect(project.issues.last.zoom_meetings.first.url).to eq('https://zoom.us/j/123456789')
      end
    end

    context 'sentry issue' do
      let(:issue) { minimal_issue.merge(sentry_issue: { sentry_issue_identifier: '1234567891' }).deep_stringify_keys }

      it 'restores sentry issue information' do
        pipeline.run

        expect(project.issues.last.sentry_issue.sentry_issue_identifier).to eq(1234567891)
      end
    end

    context 'issue state' do
      let(:issue) { minimal_issue.merge(state: 'closed').deep_stringify_keys }

      it 'restores issue state' do
        pipeline.run

        expect(project.issues.last.state).to eq('closed')
      end
    end

    context 'labels' do
      let(:issue) do
        minimal_issue.merge(
          label_links: [
            { label: { title: 'imported label 1', type: 'ProjectLabel' } },
            { label: { title: 'imported label 2', type: 'ProjectLabel' } }
          ]
        ).deep_stringify_keys
      end

      it 'restores issue labels' do
        pipeline.run

        expect(project.issues.last.labels.pluck(:title)).to contain_exactly('imported label 1', 'imported label 2')
      end
    end

    context 'milestone' do
      let(:issue) { minimal_issue.merge(milestone: { title: 'imported milestone' }).deep_stringify_keys }

      it 'restores issue milestone' do
        pipeline.run

        expect(project.issues.last.milestone.title).to eq('imported milestone')
      end
    end

    context 'notes' do
      let(:issue) do
        minimal_issue.merge(
          notes: [
            {
              note: 'Issue note',
              author_id: 101,
              award_emoji: [{ name: 'clapper', user_id: 101 }]
            }
          ]
        ).deep_stringify_keys
      end

      it 'restores issue notes and their award emoji' do
        pipeline.run

        note = project.issues.last.notes.first

        aggregate_failures do
          expect(note.note).to eq('Issue note')
          expect(note.award_emoji.first.name).to eq('clapper')
        end
      end

      context 'when importing an issue with one award emoji and other relations with one item' do
        let(:issue) do
          minimal_issue.merge(
            notes: [{ note: 'Description changed', author_id: 101 }],
            award_emoji: [{ name: AwardEmoji::THUMBS_UP, user_id: 101 }]
          ).deep_stringify_keys
        end

        it 'saves properly' do
          pipeline.run

          issue = project.issues.last
          notes = issue.notes

          aggregate_failures do
            expect(notes.count).to eq(1)
            expect(notes[0].note).to include('Description changed')
            expect(issue.award_emoji.first.name).to eq(AwardEmoji::THUMBS_UP)
          end
        end
      end
    end

    context 'when direct reassignment is supported' do
      before do
        allow(Import::DirectReassignService).to receive(:supported?).and_return(true)
      end

      it 'does not push any placeholder references' do
        pipeline.run

        expect(Import::PlaceholderReferences::PushService).not_to have_received(:from_record)
      end
    end
  end
end
