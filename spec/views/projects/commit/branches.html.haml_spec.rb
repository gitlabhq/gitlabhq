require 'spec_helper'

describe 'projects/commit/branches.html.haml' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
  end

  context 'branches and tags' do
    before do
      assign(:branches, ['master', 'test-branch'])
      assign(:branches_limit_exceeded, false)
      assign(:tags, ['tag1'])
      assign(:tags_limit_exceeded, false)

      render
    end

    it 'shows branch and tag links' do
      expect(rendered).to have_link('master')
      expect(rendered).to have_link('test-branch')
      expect(rendered).to have_link('tag1')
    end
  end

  context 'throttled branches and tags' do
    before do
      assign(:branches, [])
      assign(:branches_limit_exceeded, true)
      assign(:tags, [])
      assign(:tags_limit_exceeded, true)

      render
    end

    it 'shows too many to search' do
      expect(rendered).to have_text('Branches unavailable')
      expect(rendered).to have_text('Tags unavailable')
    end
  end
end
