# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/tree/_tree_row' do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  # rubocop: disable Rails/FindBy
  # This is not ActiveRecord where..first
  let(:blob_item) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }
  # rubocop: enable Rails/FindBy

  before do
    assign(:project, project)
    assign(:repository, repository)
    assign(:id, File.join('master', ''))
    assign(:lfs_blob_ids, [])
  end

  it 'renders blob item' do
    render_partial(blob_item)

    expect(rendered).to have_content(blob_item.name)
    expect(rendered).not_to have_selector('.label-lfs', text: 'LFS')
  end

  describe 'LFS blob' do
    before do
      assign(:lfs_blob_ids, [blob_item].map(&:id))

      render_partial(blob_item)
    end

    it 'renders LFS badge' do
      expect(rendered).to have_selector('.label-lfs', text: 'LFS')
    end
  end

  def render_partial(items)
    render partial: 'projects/tree/tree_row', collection: [items].flatten
  end
end
