# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::IssuesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity) do
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

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:issue_attributes) { {} }
  let(:issue) do
    {
      'iid' => 7,
      'title' => 'Imported Issue',
      'description' => 'Description',
      'state' => 'opened',
      'updated_at' => '2016-06-14T15:02:47.967Z',
      'author_id' => 22
    }.merge(issue_attributes)
  end

  let(:importer_user_mapping_enabled) { false }

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)
      issue_with_index = [issue, 0]

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [issue_with_index]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)
      allow(context).to receive(:importer_user_mapping_enabled?).and_return(importer_user_mapping_enabled)
      allow(Import::PlaceholderReferences::PushService).to receive(:from_record).and_call_original
    end

    it 'imports issue into destination project' do
      pipeline.run

      expect(project.issues.count).to eq(1)

      imported_issue = project.issues.last

      aggregate_failures do
        expect(imported_issue.iid).to eq(7)
        expect(imported_issue.title).to eq(issue['title'])
        expect(imported_issue.description).to eq(issue['description'])
        expect(imported_issue.author).to eq(user)
        expect(imported_issue.state).to eq('opened')
        expect(imported_issue.updated_at.to_s).to eq('2016-06-14 15:02:47 UTC')
      end
    end

    context 'when an issue with the same IID exists' do
      let!(:existing_issue) { create(:issue, project: project, iid: issue['iid'], description: 'old description') }

      it 'deletes the existing record and imports a new record' do
        expect { pipeline.run }.to change { Issue.exists?(existing_issue.id) }.from(true).to(false)

        new_record = project.issues.last
        expect(project.issues.count).to eq(1)
        expect(new_record.iid).to eq(issue['iid'])
        expect(new_record.description).to eq(issue['description'])
      end
    end

    context 'zoom meetings' do
      let(:issue_attributes) { { 'zoom_meetings' => [{ 'url' => 'https://zoom.us/j/123456789' }] } }

      it 'restores zoom meetings' do
        pipeline.run

        expect(project.issues.last.zoom_meetings.first.url).to eq('https://zoom.us/j/123456789')
      end
    end

    context 'sentry issue' do
      let(:issue_attributes) { { 'sentry_issue' => { 'sentry_issue_identifier' => '1234567891' } } }

      it 'restores sentry issue information' do
        pipeline.run

        expect(project.issues.last.sentry_issue.sentry_issue_identifier).to eq(1234567891)
      end
    end

    context 'award emoji' do
      let(:issue_attributes) { { 'award_emoji' => [{ 'name' => 'musical_keyboard', 'user_id' => 22 }] } }

      it 'has award emoji on an issue' do
        pipeline.run

        award_emoji = project.issues.last.award_emoji.first

        expect(award_emoji.name).to eq('musical_keyboard')
        expect(award_emoji.user).to eq(user)
      end
    end

    context 'issue state' do
      let(:issue_attributes) { { 'state' => 'closed' } }

      it 'restores issue state' do
        pipeline.run

        expect(project.issues.last.state).to eq('closed')
      end
    end

    context 'labels' do
      let(:issue_attributes) do
        {
          'label_links' => [
            { 'label' => { 'title' => 'imported label 1', 'type' => 'ProjectLabel' } },
            { 'label' => { 'title' => 'imported label 2', 'type' => 'ProjectLabel' } }
          ]
        }
      end

      it 'restores issue labels' do
        pipeline.run

        expect(project.issues.last.labels.pluck(:title)).to contain_exactly('imported label 1', 'imported label 2')
      end
    end

    context 'milestone' do
      let(:issue_attributes) { { 'milestone' => { 'title' => 'imported milestone' } } }

      it 'restores issue milestone' do
        pipeline.run

        expect(project.issues.last.milestone.title).to eq('imported milestone')
      end
    end

    context 'timelogs' do
      let(:issue_attributes) { { 'timelogs' => [{ 'time_spent' => 72000, 'spent_at' => '2019-12-27T00:00:00.000Z', 'user_id' => 22 }] } }

      it 'restores issue timelogs' do
        pipeline.run

        timelog = project.issues.last.timelogs.first

        aggregate_failures do
          expect(timelog.time_spent).to eq(72000)
          expect(timelog.spent_at).to eq("2019-12-27T00:00:00.000Z")
        end
      end
    end

    context 'notes' do
      let(:issue_attributes) do
        {
          'notes' => [
            {
              'note' => 'Issue note',
              'author_id' => 22,
              'author' => {
                'name' => 'User 22'
              },
              'updated_at' => '2016-06-14T15:02:47.770Z',
              'award_emoji' => [
                {
                  'name' => 'clapper',
                  'user_id' => 22
                }
              ]
            }
          ]
        }
      end

      it 'restores issue notes and their award emoji' do
        pipeline.run

        note = project.issues.last.notes.first

        aggregate_failures do
          expect(note.note).to eq("Issue note\n\n *By User 22 on 2016-06-14T15:02:47*")
          expect(note.award_emoji.first.name).to eq('clapper')
        end
      end

      context "when importing an issue with one award emoji and other relations with one item" do
        let(:issue_attributes) do
          {
            "notes" => [
              {
                'note' => 'Description changed',
                'author_id' => 22,
                'author' => {
                  'name' => 'User 22'
                },
                'updated_at' => '2016-06-14T15:02:47.770Z'
              }
            ],
            'award_emoji' => [
              {
                'name' => AwardEmoji::THUMBS_UP,
                'user_id' => 22
              }
            ]
          }
        end

        it 'saves properly' do
          pipeline.run

          issue = project.issues.last
          notes = issue.notes

          aggregate_failures do
            expect(notes.count).to eq 1
            expect(notes[0].note).to include("Description changed")
            expect(issue.award_emoji.first.name).to eq AwardEmoji::THUMBS_UP
          end
        end
      end
    end

    context 'assignees' do
      let(:issue_attributes) { { 'issue_assignees' => [{ 'user_id' => user.id }] } }

      it 'restores issue assignees' do
        pipeline.run

        expect(project.issues.last.assignees).to contain_exactly(user)
      end
    end

    context 'when importer_user_mapping is enabled' do
      let_it_be(:source_user) do
        create(:import_source_user,
          import_type: ::Import::SOURCE_DIRECT_TRANSFER,
          namespace: group,
          source_user_identifier: 101,
          source_hostname: bulk_import.configuration.url
        )
      end

      let(:importer_user_mapping_enabled) { true }
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

        expect(issue.author).to be_placeholder
        expect(issue.updated_by).to be_placeholder
        expect(issue.last_edited_by).to be_placeholder
        expect(issue.closed_by).to be_placeholder
        expect(event.author).to be_placeholder
        expect(timelog.user).to be_placeholder
        expect(note.author).to be_placeholder
        expect(note.updated_by).to be_placeholder
        expect(note.resolved_by).to be_placeholder
        expect(note_event.author).to be_placeholder
        expect(resource_label_event.user).to be_placeholder
        expect(resource_milestone_event.user).to be_placeholder
        expect(resource_state_events.user).to be_placeholder
        expect(design_version.author).to be_placeholder
        expect(issue_assignee.assignee).to be_placeholder
        expect(award_emoji.user).to be_placeholder

        source_user = Import::SourceUser.find_by(source_user_identifier: 101)
        expect(source_user.placeholder_user).to be_placeholder

        expect(Import::PlaceholderReferences::PushService).to have_received(:from_record).exactly(16).times
      end
    end
  end
end
