# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::IssuesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
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

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)
      issue_with_index = [issue, 0]

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [issue_with_index]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run
    end

    it 'imports issue into destination project' do
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

    context 'zoom meetings' do
      let(:issue_attributes) { { 'zoom_meetings' => [{ 'url' => 'https://zoom.us/j/123456789' }] } }

      it 'restores zoom meetings' do
        expect(project.issues.last.zoom_meetings.first.url).to eq('https://zoom.us/j/123456789')
      end
    end

    context 'sentry issue' do
      let(:issue_attributes) { { 'sentry_issue' => { 'sentry_issue_identifier' => '1234567891' } } }

      it 'restores sentry issue information' do
        expect(project.issues.last.sentry_issue.sentry_issue_identifier).to eq(1234567891)
      end
    end

    context 'award emoji' do
      let(:issue_attributes) { { 'award_emoji' => [{ 'name' => 'musical_keyboard', 'user_id' => 22 }] } }

      it 'has award emoji on an issue' do
        award_emoji = project.issues.last.award_emoji.first

        expect(award_emoji.name).to eq('musical_keyboard')
        expect(award_emoji.user).to eq(user)
      end
    end

    context 'issue state' do
      let(:issue_attributes) { { 'state' => 'closed' } }

      it 'restores issue state' do
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
        expect(project.issues.last.labels.pluck(:title)).to contain_exactly('imported label 1', 'imported label 2')
      end
    end

    context 'milestone' do
      let(:issue_attributes) { { 'milestone' => { 'title' => 'imported milestone' } } }

      it 'restores issue milestone' do
        expect(project.issues.last.milestone.title).to eq('imported milestone')
      end
    end

    context 'timelogs' do
      let(:issue_attributes) { { 'timelogs' => [{ 'time_spent' => 72000, 'spent_at' => '2019-12-27T00:00:00.000Z', 'user_id' => 22 }] } }

      it 'restores issue timelogs' do
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
                'name' => 'thumbsup',
                'user_id' => 22
              }
            ]
          }
        end

        it 'saves properly' do
          issue = project.issues.last
          notes = issue.notes

          aggregate_failures do
            expect(notes.count).to eq 1
            expect(notes[0].note).to include("Description changed")
            expect(issue.award_emoji.first.name).to eq "thumbsup"
          end
        end
      end
    end
  end
end
