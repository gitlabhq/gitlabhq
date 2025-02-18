# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::PushPlaceholderReferences, feature_category: :importers do
  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let_it_be(:source_id) { 'source_identifier' }
  let_it_be(:project) { create(:project, :with_import_url) }
  let_it_be(:author) { create(:user) }
  let_it_be(:import_source_user) do
    create(
      :import_source_user,
      source_user_identifier: source_id,
      source_hostname: project.import_url,
      namespace_id: project.root_ancestor.id,
      placeholder_user_id: author.id
    )
  end

  let(:github_note) do
    Gitlab::GithubImport::Representation::Note.new(
      note_id: 100,
      noteable_id: 1,
      noteable_type: 'Issue',
      author: Gitlab::GithubImport::Representation::User.new(id: source_id, login: 'alice'),
      note: 'This is my note',
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let(:gitlab_note) { create(:note) }
  let(:user_mapper) { Gitlab::GithubImport::ContributionsMapper.new(project).user_mapper }

  let(:importer) { Gitlab::GithubImport::Importer::NoteImporter.new(github_note, project, client) }

  before do
    project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
  end

  describe '#push_with_record' do
    before do
      allow(::Import::PlaceholderReferences::PushService)
        .to receive_message_chain(:from_record, :execute)
    end

    it 'pushes the reference using .from_record' do
      importer.push_with_record(gitlab_note, :author_id, source_id, user_mapper)

      expect(::Import::PlaceholderReferences::PushService)
        .to have_received(:from_record)
        .with(
          import_source: ::Import::SOURCE_GITHUB,
          import_uid: project.import_state.id,
          record: gitlab_note,
          source_user: import_source_user,
          user_reference_column: :author_id)
    end

    it 'does not push a reference if source identifier is nil' do
      importer.push_with_record(gitlab_note, :author_id, nil, user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:from_record)
    end

    it 'does not push a reference if source identifier does not match an existing source user' do
      importer.push_with_record(gitlab_note, :author_id, 'unmatched_idenfier', user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:from_record)
    end
  end

  describe '#push_refs_with_ids' do
    before do
      allow(::Import::PlaceholderReferences::PushService)
        .to receive_message_chain(:new, :execute)
    end

    it 'pushes the reference using .new' do
      importer.push_refs_with_ids([gitlab_note.id], Note, source_id, user_mapper)

      expect(::Import::PlaceholderReferences::PushService)
        .to have_received(:new)
        .with(
          import_source: ::Import::SOURCE_GITHUB,
          import_uid: project.import_state.id,
          source_user_id: import_source_user.id,
          source_user_namespace_id: import_source_user.namespace_id,
          model: gitlab_note.class,
          user_reference_column: :author_id,
          numeric_key: gitlab_note.id
        )
    end

    it 'does not push a reference if source identifier is nil' do
      importer.push_refs_with_ids([gitlab_note.id], Note, nil, user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:new)
    end

    it 'does not push a reference if source identifier does not match an existing source user' do
      importer.push_refs_with_ids([gitlab_note.id], Note, 'unmatched_idenfier', user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:from_record)
    end
  end

  describe '#push_with_composite_key' do
    let(:composite_key) { { "user_id" => "user_id", "merge_request_id" => "merge_request_id" } }

    before do
      allow(::Import::PlaceholderReferences::PushService)
        .to receive_message_chain(:new, :execute)
    end

    it 'pushes the reference with composite key' do
      importer.push_with_composite_key(gitlab_note, :user_id, composite_key, source_id, user_mapper)

      expect(::Import::PlaceholderReferences::PushService)
        .to have_received(:new)
        .with(
          import_source: ::Import::SOURCE_GITHUB,
          import_uid: project.import_state.id,
          source_user_id: import_source_user.id,
          source_user_namespace_id: import_source_user.namespace_id,
          model: gitlab_note.class,
          user_reference_column: :user_id,
          composite_key: composite_key
        )
    end

    it 'does not push a reference if source identifier is nil' do
      importer.push_with_composite_key(gitlab_note, :user_id, composite_key, nil, user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:new)
    end

    it 'does not push a reference if source identifier does not match an existing source user' do
      importer.push_with_composite_key(gitlab_note, :user_id, composite_key, 'unmatched_idenfier', user_mapper)

      expect(::Import::PlaceholderReferences::PushService).not_to receive(:from_record)
    end
  end
end
