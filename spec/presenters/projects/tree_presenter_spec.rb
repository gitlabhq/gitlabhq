# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TreePresenter, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need persisted objects
  let(:repository) { project.repository }
  let(:user) { project.first_owner }

  let(:ref) { 'HEAD' }
  let(:path) { 'lib' }

  let(:commit) { repository.commit(ref) }
  let(:tree) { repository.tree(ref, path) }

  subject(:presenter) { described_class.new(tree, current_user: user) }

  describe '#permalink_path' do
    it 'returns the permalink path with commit SHA and directory path' do
      expect(presenter.permalink_path).to eq("/#{project.full_path}/-/tree/#{commit.sha}/#{path}")
    end

    context 'when tree path is empty (root tree)' do
      let(:path) { '' }

      it 'returns the permalink path pointing to the commit SHA only' do
        expect(presenter.permalink_path).to eq("/#{project.full_path}/-/tree/#{commit.sha}/")
      end
    end

    context 'when tree has no sha' do
      before do
        tree.sha = nil
      end

      it 'returns nil' do
        expect(presenter.permalink_path).to be_nil
      end
    end

    context 'when commit is not found' do
      before do
        allow(repository).to receive(:commit).and_return(nil)
      end

      let(:tree) do
        repository.tree(ref, path).tap do |t|
          t.sha = 'nonexistentsha123'
        end
      end

      it 'returns nil' do
        expect(presenter.permalink_path).to be_nil
      end
    end
  end
end
