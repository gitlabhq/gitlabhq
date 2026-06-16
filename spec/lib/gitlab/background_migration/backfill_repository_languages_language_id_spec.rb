# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRepositoryLanguagesLanguageId, feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:programming_languages) { table(:programming_languages) }
  let(:repository_languages) { table(:repository_languages) }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }

  let(:namespace) do
    namespaces.create!(name: 'ns', path: 'ns', organization_id: organization.id)
  end

  let(:project_namespace1) do
    namespaces.create!(name: 'pns1', path: 'pns1', organization_id: organization.id)
  end

  let(:project_namespace2) do
    namespaces.create!(name: 'pns2', path: 'pns2', organization_id: organization.id)
  end

  let(:project1) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace1.id,
      organization_id: organization.id
    )
  end

  let(:project2) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace2.id,
      organization_id: organization.id
    )
  end

  let!(:ruby) do
    programming_languages.create!(name: 'Ruby', color: '#701516', created_at: Time.current, language_id: 326)
  end

  let!(:javascript) do
    programming_languages.create!(name: 'JavaScript', color: '#f1e05a', created_at: Time.current, language_id: 183)
  end

  let!(:unknown_lang) do
    programming_languages.create!(name: 'UnknownLang', color: '#000000', created_at: Time.current, language_id: nil)
  end

  # Rows with language_id NULL that should be backfilled
  let!(:repo_lang_ruby_p1) do
    repository_languages.create!(
      project_id: project1.id,
      programming_language_id: ruby.id,
      share: 50.0,
      language_id: nil
    )
  end

  let!(:repo_lang_js_p1) do
    repository_languages.create!(
      project_id: project1.id,
      programming_language_id: javascript.id,
      share: 30.0,
      language_id: nil
    )
  end

  let!(:repo_lang_ruby_p2) do
    repository_languages.create!(
      project_id: project2.id,
      programming_language_id: ruby.id,
      share: 80.0,
      language_id: nil
    )
  end

  # Row with language_id already set - should not be overwritten even though
  # the value matches what the migration would write
  let!(:repo_lang_js_p2) do
    repository_languages.create!(
      project_id: project2.id,
      programming_language_id: javascript.id,
      share: 20.0,
      language_id: 183
    )
  end

  # Row referencing a programming_language with NULL language_id - should be skipped
  let!(:repo_lang_unknown_p1) do
    repository_languages.create!(
      project_id: project1.id,
      programming_language_id: unknown_lang.id,
      share: 20.0,
      language_id: nil
    )
  end

  let(:start_cursor) { [0, 0] }
  let(:end_cursor) do
    [
      repository_languages.maximum(:project_id),
      repository_languages.maximum(:programming_language_id)
    ]
  end

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :repository_languages,
      batch_column: :project_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: connection
    )
  end

  describe '#perform' do
    it 'backfills language_id from programming_languages where it is NULL', :aggregate_failures do
      migration.perform

      expect(repo_lang_ruby_p1.reload.language_id).to eq(326)
      expect(repo_lang_js_p1.reload.language_id).to eq(183)
      expect(repo_lang_ruby_p2.reload.language_id).to eq(326)
    end

    it 'does not overwrite rows that already have a language_id' do
      expect { migration.perform }
        .not_to change { repo_lang_js_p2.reload.language_id }
    end

    it 'skips rows where programming_languages.language_id is NULL' do
      migration.perform

      expect(repo_lang_unknown_p1.reload.language_id).to be_nil
    end

    it 'is idempotent' do
      migration.perform

      expect { migration.perform }
        .not_to change { repository_languages.order(:project_id, :programming_language_id).pluck(:language_id) }
    end
  end
end
