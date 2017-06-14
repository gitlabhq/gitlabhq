require 'spec_helper'

describe 'projects/notes/_more_actions_dropdown', :view do
  let(:author_user) { create(:user) }
  let(:not_author_user) { create(:user) }

  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note_on_issue, author: author_user, noteable: issue, project: project) }

  before do
    allow(view).to receive(:note).and_return(note)
    assign(:project, project)
  end

  context 'not editable and not current users comment' do
    before do
      allow(view).to receive(:note_editable).and_return(false)
      allow(view).to receive(:current_user).and_return(not_author_user)

      render
    end

    it 'shows Report as abuse button' do
      expect(rendered).to have_link('Report as abuse')
    end
  end

  context 'not editable and current users comment' do
    before do
      allow(view).to receive(:note_editable).and_return(false)
      allow(view).to receive(:current_user).and_return(author_user)

      render
    end

    it 'does not show the More actions button' do
      expect(rendered).not_to have_selector('.dropdown.more-actions')
    end
  end

  context 'editable and not current users comment' do
    before do
      allow(view).to receive(:note_editable).and_return(true)
      allow(view).to receive(:current_user).and_return(not_author_user)

      render
    end

    it 'shows Report as abuse, Edit and Delete buttons' do
      expect(rendered).to have_link('Report as abuse')
      expect(rendered).to have_button('Edit comment')
      expect(rendered).to have_link('Delete comment')
    end
  end

  context 'editable and current users comment' do
    before do
      allow(view).to receive(:note_editable).and_return(true)
      allow(view).to receive(:current_user).and_return(author_user)

      render
    end

    it 'shows Edit and Delete buttons' do
      expect(rendered).to have_button('Edit comment')
      expect(rendered).to have_link('Delete comment')
    end
  end
end
