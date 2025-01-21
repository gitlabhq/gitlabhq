# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::WikiRepository, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

  let(:project_path) { project.repository.full_path }
  let(:wiki_path) { project.wiki.repository.full_path }
  let(:design_path) { project.design_repository.full_path }
  let(:personal_snippet_path) { "snippets/#{personal_snippet.id}" }
  let(:project_snippet_path) { "#{project.full_path}/snippets/#{project_snippet.id}" }
  let(:wiki) { project.wiki }

  subject(:wiki_repository) { described_class.instance }

  it_behaves_like 'a repo type' do
    let(:expected_identifier) { "wiki-#{wiki.project.id}" }
    let(:expected_suffix) { '.wiki' }
    let(:expected_container) { wiki }
    let(:expected_repository) do
      ::Repository.new(wiki.full_path, wiki, shard: wiki.repository_storage,
        disk_path: wiki.disk_path, repo_type: wiki_repository)
    end
  end

  it 'knows its type' do
    aggregate_failures do
      expect(wiki_repository).to be_wiki
      expect(wiki_repository).not_to be_project
      expect(wiki_repository).not_to be_snippet
      expect(wiki_repository).not_to be_design
    end
  end

  it 'checks if repository path is valid' do
    aggregate_failures do
      expect(wiki_repository.valid?(project_path)).to be_falsey
      expect(wiki_repository.valid?(wiki_path)).to be_truthy
      expect(wiki_repository.valid?(personal_snippet_path)).to be_falsey
      expect(wiki_repository.valid?(project_snippet_path)).to be_falsey
      expect(wiki_repository.valid?(design_path)).to be_falsey
    end
  end
end
