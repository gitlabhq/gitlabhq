# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeEntryPresenter do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:tree) { Gitlab::Graphql::Representation::TreeEntry.new(repository.tree(ref).trees.first, repository) }
  let(:presenter) { described_class.new(tree) }
  let(:ref) { 'master' }

  describe '.web_url' do
    it {
      expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/tree/#{ref}/#{tree.path}")
    }
  end

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{project.full_path}/-/tree/#{ref}/#{tree.path}") }
  end

  context 'when tree has ref_type' do
    before do
      tree.ref_type = 'heads'
    end

    describe '.web_url' do
      it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/tree/#{ref}/#{tree.path}?ref_type=heads") }
    end

    describe '#web_path' do
      it {
        expect(presenter.web_path).to eq("/#{project.full_path}/-/tree/#{ref}/#{tree.path}?ref_type=heads")
      }
    end
  end
end
