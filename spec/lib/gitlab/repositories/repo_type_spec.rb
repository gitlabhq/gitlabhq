# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::RepoType, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
  let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

  let(:project_path) { project.repository.full_path }
  let(:wiki_path) { project.wiki.repository.full_path }
  let(:design_path) { project.design_repository.full_path }
  let(:personal_snippet_path) { "snippets/#{personal_snippet.id}" }
  let(:project_snippet_path) { "#{project.full_path}/snippets/#{project_snippet.id}" }

  subject(:repo_type) { described_class.new }

  context 'with abstract methods' do
    describe '#name' do
      it 'raises a NotImplementedError' do
        expect { repo_type.name }.to raise_error NotImplementedError
      end
    end

    describe '#access_checker_class' do
      it 'raises a NotImplementedError' do
        expect { repo_type.access_checker_class }.to raise_error NotImplementedError
      end
    end

    describe '#guest_read_ability' do
      it 'raises a NotImplementedError' do
        expect { repo_type.guest_read_ability }.to raise_error NotImplementedError
      end
    end

    describe '#container_class' do
      it 'raises a NotImplementedError' do
        expect { repo_type.container_class }.to raise_error NotImplementedError
      end
    end

    describe '#project_for' do
      it 'raises a NotImplementedError' do
        expect { repo_type.project_for(project) }.to raise_error NotImplementedError
      end
    end

    describe '#repository_resolver' do
      it 'raises a NotImplementedError' do
        expect { repo_type.send(:repository_resolver, project) }.to raise_error NotImplementedError
      end
    end
  end
end
