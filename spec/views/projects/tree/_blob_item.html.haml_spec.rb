require 'spec_helper'

describe 'projects/tree/_blob_item' do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:blob_item) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }

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

  def render_partial(blob_item)
    render partial: 'projects/tree/blob_item', locals: {
      blob_item: blob_item,
      type: 'blob'
    }
  end
end
