# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::GlRepository::RepoType do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.owner) }

  let(:project_path) { project.repository.full_path }
  let(:wiki_path) { project.wiki.repository.full_path }
  let(:design_path) { project.design_repository.full_path }
  let(:personal_snippet_path) { "snippets/#{personal_snippet.id}" }
  let(:project_snippet_path) { "#{project.full_path}/snippets/#{project_snippet.id}" }

  describe Gitlab::GlRepository::PROJECT do
    it_behaves_like 'a repo type' do
      let(:expected_id) { project.id }
      let(:expected_identifier) { "project-#{expected_id}" }
      let(:expected_suffix) { '' }
      let(:expected_container) { project }
      let(:expected_repository) { ::Repository.new(project.full_path, project, shard: project.repository_storage, disk_path: project.disk_path, repo_type: Gitlab::GlRepository::PROJECT) }
    end

    it 'knows its type' do
      aggregate_failures do
        expect(described_class).not_to be_wiki
        expect(described_class).to be_project
        expect(described_class).not_to be_snippet
        expect(described_class).not_to be_design
      end
    end

    it 'checks if repository path is valid' do
      aggregate_failures do
        expect(described_class.valid?(project_path)).to be_truthy
        expect(described_class.valid?(wiki_path)).to be_truthy
        expect(described_class.valid?(personal_snippet_path)).to be_truthy
        expect(described_class.valid?(project_snippet_path)).to be_truthy
        expect(described_class.valid?(design_path)).to be_truthy
      end
    end
  end

  describe Gitlab::GlRepository::WIKI do
    let(:wiki) { project.wiki }

    it_behaves_like 'a repo type' do
      let(:expected_id) { wiki.project.id }
      let(:expected_identifier) { "wiki-#{expected_id}" }
      let(:expected_suffix) { '.wiki' }
      let(:expected_container) { wiki }
      let(:expected_repository) { ::Repository.new(wiki.full_path, wiki, shard: wiki.repository_storage, disk_path: wiki.disk_path, repo_type: Gitlab::GlRepository::WIKI) }
    end

    it 'knows its type' do
      aggregate_failures do
        expect(described_class).to be_wiki
        expect(described_class).not_to be_project
        expect(described_class).not_to be_snippet
        expect(described_class).not_to be_design
      end
    end

    it 'checks if repository path is valid' do
      aggregate_failures do
        expect(described_class.valid?(project_path)).to be_falsey
        expect(described_class.valid?(wiki_path)).to be_truthy
        expect(described_class.valid?(personal_snippet_path)).to be_falsey
        expect(described_class.valid?(project_snippet_path)).to be_falsey
        expect(described_class.valid?(design_path)).to be_falsey
      end
    end
  end

  describe Gitlab::GlRepository::SNIPPET do
    context 'when PersonalSnippet' do
      it_behaves_like 'a repo type' do
        let(:expected_id) { personal_snippet.id }
        let(:expected_identifier) { "snippet-#{expected_id}" }
        let(:expected_suffix) { '' }
        let(:expected_repository) { ::Repository.new(personal_snippet.full_path, personal_snippet, shard: personal_snippet.repository_storage, disk_path: personal_snippet.disk_path, repo_type: Gitlab::GlRepository::SNIPPET) }
        let(:expected_container) { personal_snippet }
      end

      it 'knows its type' do
        aggregate_failures do
          expect(described_class).to be_snippet
          expect(described_class).not_to be_wiki
          expect(described_class).not_to be_project
          expect(described_class).not_to be_design
        end
      end

      it 'checks if repository path is valid' do
        aggregate_failures do
          expect(described_class.valid?(project_path)).to be_falsey
          expect(described_class.valid?(wiki_path)).to be_falsey
          expect(described_class.valid?(personal_snippet_path)).to be_truthy
          expect(described_class.valid?(project_snippet_path)).to be_truthy
          expect(described_class.valid?(design_path)).to be_falsey
        end
      end
    end

    context 'when ProjectSnippet' do
      it_behaves_like 'a repo type' do
        let(:expected_id) { project_snippet.id }
        let(:expected_identifier) { "snippet-#{expected_id}" }
        let(:expected_suffix) { '' }
        let(:expected_repository) { ::Repository.new(project_snippet.full_path, project_snippet, shard: project_snippet.repository_storage, disk_path: project_snippet.disk_path, repo_type: Gitlab::GlRepository::SNIPPET) }
        let(:expected_container) { project_snippet }
      end

      it 'knows its type' do
        aggregate_failures do
          expect(described_class).to be_snippet
          expect(described_class).not_to be_wiki
          expect(described_class).not_to be_project
        end
      end

      it 'checks if repository path is valid' do
        aggregate_failures do
          expect(described_class.valid?(project_path)).to be_falsey
          expect(described_class.valid?(wiki_path)).to be_falsey
          expect(described_class.valid?(personal_snippet_path)).to be_truthy
          expect(described_class.valid?(project_snippet_path)).to be_truthy
          expect(described_class.valid?(design_path)).to be_falsey
        end
      end
    end
  end

  describe Gitlab::GlRepository::DESIGN do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "design-#{project.id}" }
      let(:expected_id) { project.id }
      let(:expected_suffix) { '.design' }
      let(:expected_repository) { ::DesignManagement::Repository.new(project) }
      let(:expected_container) { project }
    end

    it 'uses the design access checker' do
      expect(described_class.access_checker_class).to eq(::Gitlab::GitAccessDesign)
    end

    it 'knows its type' do
      aggregate_failures do
        expect(described_class).to be_design
        expect(described_class).not_to be_project
        expect(described_class).not_to be_wiki
        expect(described_class).not_to be_snippet
      end
    end

    it 'checks if repository path is valid' do
      aggregate_failures do
        expect(described_class.valid?(design_path)).to be_truthy
        expect(described_class.valid?(project_path)).to be_falsey
        expect(described_class.valid?(wiki_path)).to be_falsey
        expect(described_class.valid?(personal_snippet_path)).to be_falsey
        expect(described_class.valid?(project_snippet_path)).to be_falsey
      end
    end
  end
end
