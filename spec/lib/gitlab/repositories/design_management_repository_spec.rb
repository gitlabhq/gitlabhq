# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::DesignManagementRepository, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

  let(:project_path) { project.repository.full_path }
  let(:wiki_path) { project.wiki.repository.full_path }
  let(:design_path) { project.design_repository.full_path }
  let(:personal_snippet_path) { "snippets/#{personal_snippet.id}" }
  let(:project_snippet_path) { "#{project.full_path}/snippets/#{project_snippet.id}" }

  subject(:design_repository) { described_class.instance }

  it_behaves_like 'a repo type' do
    let(:expected_repository) { project.design_repository }
    let(:expected_container) { project.design_management_repository }
    let(:expected_identifier) { "design-#{expected_container.id}" }
    let(:expected_suffix) { '.design' }

    describe '#repository_for' do
      it 'raises an error when container class does not match given container_class' do
        user = build(:user)

        expected_message = "Expected container class to be #{design_repository.container_class} for " \
          "repo type #{design_repository.name}, but found #{user.class.name} instead."

        expect do
          design_repository.repository_for(user)
        end.to raise_error(Gitlab::Repositories::ContainerClassMismatchError, expected_message)
      end
    end
  end

  it 'uses the design access checker' do
    expect(design_repository.access_checker_class).to eq(::Gitlab::GitAccessDesign)
  end

  it 'knows its type' do
    aggregate_failures do
      expect(design_repository).to be_design
      expect(design_repository).not_to be_project
      expect(design_repository).not_to be_wiki
      expect(design_repository).not_to be_snippet
    end
  end

  it 'checks if repository path is valid' do
    aggregate_failures do
      expect(design_repository.valid?(design_path)).to be_truthy
      expect(design_repository.valid?(project_path)).to be_falsey
      expect(design_repository.valid?(wiki_path)).to be_falsey
      expect(design_repository.valid?(personal_snippet_path)).to be_falsey
      expect(design_repository.valid?(project_snippet_path)).to be_falsey
    end
  end

  describe '.project_for' do
    it 'returns a project when container is a design_management_repository' do
      expect(design_repository.project_for(project.design_management_repository)).to be_instance_of(Project)
    end
  end
end
