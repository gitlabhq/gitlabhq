require 'spec_helper'

describe 'projects/commit/show.html.haml', :view do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    assign(:commit, project.commit)
    assign(:noteable, project.commit)
    assign(:notes, [])
    assign(:diffs, project.commit.diffs)

    allow(view).to receive(:current_user).and_return(nil)
    allow(view).to receive(:can?).and_return(false)
    allow(view).to receive(:can_collaborate_with_project?).and_return(false)
    allow(view).to receive(:current_ref).and_return(project.repository.root_ref)
    allow(view).to receive(:diff_btn).and_return('')
  end

  context 'inline diff view' do
    before do
      allow(view).to receive(:diff_view).and_return(:inline)

      render
    end

    it 'keeps container-limited' do
      expect(rendered).not_to have_selector('.limit-container-width')
    end
  end

  context 'parallel diff view' do
    before do
      allow(view).to receive(:diff_view).and_return(:parallel)

      render
    end

    it 'spans full width' do
      expect(rendered).to have_selector('.limit-container-width')
    end
  end
end
