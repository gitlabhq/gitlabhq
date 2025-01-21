# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::SnippetRepository, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

  let(:project_path) { project.repository.full_path }
  let(:wiki_path) { project.wiki.repository.full_path }
  let(:design_path) { project.design_repository.full_path }
  let(:personal_snippet_path) { "snippets/#{personal_snippet.id}" }
  let(:project_snippet_path) { "#{project.full_path}/snippets/#{project_snippet.id}" }

  subject(:snippet_repository) { described_class.instance }

  context 'when PersonalSnippet' do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "snippet-#{personal_snippet.id}" }
      let(:expected_suffix) { '' }
      let(:expected_container) { personal_snippet }
      let(:expected_repository) do
        ::Repository.new(personal_snippet.full_path, personal_snippet, shard: personal_snippet.repository_storage,
          disk_path: personal_snippet.disk_path, repo_type: snippet_repository)
      end

      describe '#repository_for' do
        it 'raises an error when container class does not match given container_class' do
          user = build(:user)

          expected_message = "Expected container class to be #{snippet_repository.container_class} for " \
            "repo type #{snippet_repository.name}, but found #{user.class.name} instead."

          expect do
            snippet_repository.repository_for(user)
          end.to raise_error(Gitlab::Repositories::ContainerClassMismatchError, expected_message)
        end
      end
    end

    it 'knows its type' do
      aggregate_failures do
        expect(snippet_repository).to be_snippet
        expect(snippet_repository).not_to be_wiki
        expect(snippet_repository).not_to be_project
        expect(snippet_repository).not_to be_design
      end
    end

    it 'checks if repository path is valid' do
      aggregate_failures do
        expect(snippet_repository.valid?(project_path)).to be_falsey
        expect(snippet_repository.valid?(wiki_path)).to be_falsey
        expect(snippet_repository.valid?(personal_snippet_path)).to be_truthy
        expect(snippet_repository.valid?(project_snippet_path)).to be_truthy
        expect(snippet_repository.valid?(design_path)).to be_falsey
      end
    end
  end

  context 'when ProjectSnippet' do
    it_behaves_like 'a repo type' do
      let(:expected_id) { project_snippet.id }
      let(:expected_identifier) { "snippet-#{expected_id}" }
      let(:expected_suffix) { '' }
      let(:expected_container) { project_snippet }
      let(:expected_repository) do
        ::Repository.new(project_snippet.full_path, project_snippet, shard: project_snippet.repository_storage,
          disk_path: project_snippet.disk_path, repo_type: snippet_repository)
      end
    end

    it 'knows its type' do
      aggregate_failures do
        expect(snippet_repository).to be_snippet
        expect(snippet_repository).not_to be_wiki
        expect(snippet_repository).not_to be_project
      end
    end

    it 'checks if repository path is valid' do
      aggregate_failures do
        expect(snippet_repository.valid?(project_path)).to be_falsey
        expect(snippet_repository.valid?(wiki_path)).to be_falsey
        expect(snippet_repository.valid?(personal_snippet_path)).to be_truthy
        expect(snippet_repository.valid?(project_snippet_path)).to be_truthy
        expect(snippet_repository.valid?(design_path)).to be_falsey
      end
    end
  end
end
