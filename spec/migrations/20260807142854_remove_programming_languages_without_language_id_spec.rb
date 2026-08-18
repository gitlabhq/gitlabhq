# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveProgrammingLanguagesWithoutLanguageId,
  migration: :gitlab_main_cell_local,
  feature_category: :source_code_management do
  let(:programming_languages) { table(:programming_languages) }
  let(:repository_languages) { table(:repository_languages) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(true)
  end

  describe '#up' do
    context 'when a programming language has no language ID' do
      it 'deletes only the programming language', :aggregate_failures do
        programming_language = create_programming_language(name: 'Unknown', language_id: nil)
        repository_language = repository_languages.create!(
          project_id: create_project.id,
          programming_language_id: programming_language.id,
          language_id: 999,
          share: 100
        )

        migrate!

        expect(programming_languages.where(id: programming_language.id)).not_to exist
        expect(repository_languages.where(
          project_id: repository_language.project_id,
          programming_language_id: repository_language.programming_language_id
        )).to exist
      end
    end

    context 'when a programming language has a language ID' do
      it 'keeps the programming language and its repository language', :aggregate_failures do
        programming_language = create_programming_language(name: 'Ruby', language_id: 326)
        repository_language = repository_languages.create!(
          project_id: create_project.id,
          programming_language_id: programming_language.id,
          language_id: programming_language.language_id,
          share: 100
        )

        migrate!

        expect(programming_languages.where(id: programming_language.id)).to exist
        expect(repository_languages.where(project_id: repository_language.project_id)).to exist
      end
    end

    context 'with programming languages with and without language IDs' do
      it 'only deletes programming languages without language IDs', :aggregate_failures do
        programming_language_without_id = create_programming_language(name: 'Unknown', language_id: nil)
        programming_language_with_id = create_programming_language(name: 'Ruby', language_id: 326)

        migrate!

        expect(programming_languages.where(id: programming_language_without_id.id)).not_to exist
        expect(programming_languages.where(id: programming_language_with_id.id)).to exist
      end
    end

    context 'when there are no programming languages without language IDs' do
      it 'does not delete any programming languages' do
        programming_language = create_programming_language(name: 'Ruby', language_id: 326)

        expect { migrate! }.not_to change { programming_languages.where(id: programming_language.id).count }
      end
    end

    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not delete programming languages without language IDs' do
        programming_language = create_programming_language(name: 'Unknown', language_id: nil)

        migrate!

        expect(programming_languages.where(id: programming_language.id)).to exist
      end
    end
  end

  def create_programming_language(name:, language_id:)
    programming_languages.create!(
      name: name,
      color: '#000000',
      language_id: language_id,
      created_at: Time.current
    )
  end

  def create_project
    organization = organizations.create!(name: 'Organization', path: 'organization')
    group = namespaces.create!(
      name: 'Group', path: 'group', type: 'Group', organization_id: organization.id
    )
    project_namespace = namespaces.create!(
      name: 'Project', path: 'project', type: 'Project', organization_id: organization.id
    )

    projects.create!(
      name: 'Project', path: 'project', namespace_id: group.id,
      project_namespace_id: project_namespace.id, organization_id: organization.id
    )
  end
end
