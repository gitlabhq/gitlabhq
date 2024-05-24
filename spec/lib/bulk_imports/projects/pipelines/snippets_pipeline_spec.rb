# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::SnippetsPipeline, feature_category: :importers do
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

  let(:snippet_attributes) { {} }
  let(:exported_snippet) do
    {
      'id' => 25,
      'title' => 'Snippet with 2 files',
      'content' => 'content',
      'author_id' => 22,
      'project_id' => 6,
      'created_at' => '2021-10-28T20:21:59.712Z',
      'updated_at' => '2021-10-28T20:31:10.408Z',
      'file_name' => 'galactic_empire.rb',
      'visibility_level' => 0,
      'description' => 'How to track your Galactic armies.'
    }.merge(snippet_attributes)
  end

  subject(:pipeline) { described_class.new(context) }

  describe '#run', :clean_gitlab_redis_shared_state do
    before do
      group.add_owner(user)
      snippet_with_index = [exported_snippet.dup, 0]

      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [snippet_with_index]))
      end

      allow(pipeline).to receive(:set_source_objects_counter)

      pipeline.run
    end

    it 'imports snippet into destination project' do
      imported_snippet = project.snippets.last

      expect(imported_snippet).to have_attributes(
        title: exported_snippet['title'],
        content: exported_snippet['content'],
        author_id: user.id,
        created_at: DateTime.parse(exported_snippet['created_at']),
        updated_at: DateTime.parse(exported_snippet['updated_at']),
        file_name: exported_snippet['file_name'],
        visibility_level: exported_snippet['visibility_level'])
    end

    context 'with award_emoji' do
      let(:snippet_attributes) { { 'award_emoji' => [expected_award] } }
      let(:expected_award) do
        {
          'id' => 580,
          'name' => 'rocket',
          'user_id' => 1,
          'awardable_type' => 'Snippet',
          'created_at' => '2021-10-28T20:30:25.802Z',
          'updated_at' => '2021-10-28T20:30:25.802Z'
        }
      end

      it 'restores the award_emoji' do
        snippet_award = project.snippets.first.award_emoji.first

        expect(snippet_award).to have_attributes(
          name: expected_award['name'],
          user_id: user.id,
          awardable_type: expected_award['awardable_type'],
          created_at: DateTime.parse(expected_award['created_at']),
          updated_at: DateTime.parse(expected_award['updated_at']))
      end
    end

    context 'with notes', :freeze_time do
      # To properly emulate a fixture that is expected to be read from a file, we dump a json
      # object, then parse it right away. We expected that some attrs like Datetimes be
      # converted to Strings.
      let(:exported_snippet) { Gitlab::Json.parse(note.noteable.attributes.merge('notes' => notes).to_json) }
      let(:note) { create(:note_on_project_snippet, :with_attachment) }
      let(:notes) { [note.attributes.merge('author' => { 'name' => note.author.name })] }

      it 'restores the notes' do
        snippet_note = project.snippets.last.notes.first
        author_name = note.author.name
        note_updated_at = exported_snippet['notes'].first['updated_at'].split('.').first

        expect(snippet_note).to have_attributes(
          note: note.note + "\n\n *By #{author_name} on #{note_updated_at}*",
          noteable_type: note.noteable_type,
          author_id: user.id,
          updated_at: note.updated_at,
          line_code: note.line_code,
          commit_id: note.commit_id,
          system: note.system,
          st_diff: note.st_diff,
          updated_by_id: user.id)
      end
    end
  end
end
