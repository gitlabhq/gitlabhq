# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupRepositoryLanguagesLanguageId,
  feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:programming_languages) { table(:programming_languages) }
  let(:repository_languages) { table(:repository_languages) }
  let(:sub_batch_size) { 100 }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }
  let(:namespace) { namespaces.create!(name: 'ns', path: 'ns', organization_id: organization.id) }

  let(:migration) do
    described_class.new(
      start_cursor: [0, 0],
      end_cursor: [repository_languages.maximum(:project_id), repository_languages.maximum(:programming_language_id)],
      batch_table: :repository_languages,
      batch_column: :project_id,
      sub_batch_size: sub_batch_size,
      pause_ms: 0,
      connection: connection
    )
  end

  def create_project(suffix)
    project_namespace = namespaces.create!(
      name: "project-#{suffix}",
      path: "project-#{suffix}",
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  def create_programming_language(name, language_id:)
    programming_languages.create!(
      name: name,
      color: '#000000',
      created_at: Time.current,
      language_id: language_id
    )
  end

  def create_repository_language(project, programming_language, language_id: nil)
    repository_languages.create!(
      project_id: project.id,
      programming_language_id: programming_language.id,
      share: 50.0,
      language_id: language_id
    )
  end

  describe '#perform' do
    context 'with copyable rows' do
      it 'copies parent language IDs using the composite key', :aggregate_failures do
        project = create_project('copyable')
        ruby = create_programming_language('Ruby', language_id: 326)
        javascript = create_programming_language('JavaScript', language_id: 183)
        ruby_row = create_repository_language(project, ruby)
        javascript_row = create_repository_language(project, javascript)

        migration.perform

        expect(ruby_row.reload.language_id).to eq(326)
        expect(javascript_row.reload.language_id).to eq(183)
        expect(repository_languages.where(project_id: project.id).count).to eq(2)
      end
    end

    context 'with an already-correct row' do
      it 'does not overwrite or delete it', :aggregate_failures do
        project = create_project('correct')
        ruby = create_programming_language('Ruby', language_id: 326)
        repository_language = create_repository_language(project, ruby, language_id: 999)

        migration.perform

        expect(repository_language.reload.language_id).to eq(999)
        expect(repository_languages.exists?(project_id: project.id, programming_language_id: ruby.id)).to be(true)
      end
    end

    context 'with an unresolvable row' do
      it 'deletes it' do
        project = create_project('unresolvable')
        unknown = create_programming_language('Unknown', language_id: nil)
        create_repository_language(project, unknown)

        migration.perform

        expect(repository_languages.where(project_id: project.id)).to be_empty
      end
    end

    context 'with resolvable and unresolvable rows for the same project' do
      it 'deletes only the unresolvable project-language pair', :aggregate_failures do
        project = create_project('tuple-precision')
        ruby = create_programming_language('Ruby', language_id: 326)
        unknown = create_programming_language('Unknown', language_id: nil)
        ruby_row = create_repository_language(project, ruby)
        create_repository_language(project, unknown)

        migration.perform

        expect(repository_languages.exists?(project_id: project.id, programming_language_id: ruby.id)).to be(true)
        expect(ruby_row.reload.language_id).to eq(326)
        expect(repository_languages.exists?(project_id: project.id, programming_language_id: unknown.id)).to be(false)
      end
    end

    context 'with multiple deleted languages for one project' do
      it 'deletes every unresolved tuple while preserving a valid tuple', :aggregate_failures do
        project = create_project('duplicates')
        unknown_one = create_programming_language('UnknownOne', language_id: nil)
        unknown_two = create_programming_language('UnknownTwo', language_id: nil)
        ruby = create_programming_language('Ruby', language_id: 326)
        create_repository_language(project, unknown_one)
        create_repository_language(project, unknown_two)
        ruby_row = create_repository_language(project, ruby)

        migration.perform

        expect(repository_languages.exists?(
          project_id: project.id, programming_language_id: unknown_one.id
        )).to be(false)
        expect(repository_languages.exists?(
          project_id: project.id, programming_language_id: unknown_two.id
        )).to be(false)
        expect(ruby_row.reload.language_id).to eq(326)
      end
    end

    context 'with the same unresolved language across multiple projects' do
      it 'deletes every unresolved tuple while preserving a resolved tuple', :aggregate_failures do
        project_one = create_project('affected-one')
        project_two = create_project('affected-two')
        unknown = create_programming_language('Unknown', language_id: nil)
        ruby = create_programming_language('Ruby', language_id: 326)
        create_repository_language(project_one, unknown)
        create_repository_language(project_two, unknown)
        ruby_row = create_repository_language(project_one, ruby)

        migration.perform

        expect(repository_languages.exists?(
          project_id: project_one.id, programming_language_id: unknown.id
        )).to be(false)
        expect(repository_languages.exists?(
          project_id: project_two.id, programming_language_id: unknown.id
        )).to be(false)
        expect(ruby_row.reload.language_id).to eq(326)
      end
    end

    context 'with unresolved rows interleaved across sub-batches' do
      let(:sub_batch_size) { 1 }

      it 'processes each keyspace window without skipping or front-loading rows', :aggregate_failures do
        unknown = create_programming_language('Unknown', language_id: nil)
        ruby = create_programming_language('Ruby', language_id: 326)
        deleted_project_ids = []
        resolved_rows = []

        2.times do |index|
          project = create_project("interleaved-#{index}")

          if index.even?
            create_repository_language(project, unknown)
            deleted_project_ids << project.id
          else
            resolved_rows << create_repository_language(project, ruby)
          end
        end

        migration.perform

        expect(repository_languages.where(project_id: deleted_project_ids)).to be_empty
        expect(resolved_rows.map { |row| row.reload.language_id }).to all(eq(326))
      end
    end

    context 'with a no-op batch' do
      it 'does not change rows' do
        project = create_project('no-op')
        ruby = create_programming_language('Ruby', language_id: 326)
        repository_language = create_repository_language(project, ruby, language_id: 999)

        expect { migration.perform }.not_to change { repository_language.reload.attributes }
      end
    end

    context 'when performed twice' do
      it 'is idempotent' do
        project = create_project('retry')
        unknown = create_programming_language('Unknown', language_id: nil)
        create_repository_language(project, unknown)

        migration.perform
        migration.perform

        expect(repository_languages.where(project_id: project.id)).to be_empty
      end
    end
  end
end
