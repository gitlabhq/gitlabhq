# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/notes/_more_actions_dropdown' do
  let(:author_user) { create(:user) }
  let(:not_author_user) { create(:user) }

  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note_on_issue, author: author_user, noteable: issue, project: project) }

  before do
    assign(:project, project)
  end

  it 'shows Report abuse to admin button if not editable and not current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: not_author_user, note_editable: false, note: note

    expect(rendered).to have_selector('.js-report-abuse-dropdown-item')
  end

  it 'does not show the More actions button if not editable and current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: author_user, note_editable: false, note: note

    expect(rendered).not_to have_selector('.dropdown.more-actions')
  end

  it 'shows Report abuse and Delete buttons if editable and not current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: not_author_user, note_editable: true, note: note

    expect(rendered).to have_selector('.js-report-abuse-dropdown-item')

    expect(rendered).to have_link('Delete comment')
  end

  it 'shows Delete button if editable and current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: author_user, note_editable: true, note: note

    expect(rendered).to have_link('Delete comment')
  end

  it 'shows Edit button if editable and current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: author_user, note_editable: true, note: note

    expect(rendered).to have_selector('.js-note-edit')

    expect(rendered).to have_button('Edit comment')
  end

  it 'does not show Edit button if not editable and not current users comment' do
    render 'projects/notes/more_actions_dropdown', current_user: not_author_user, note_editable: false, note: note

    expect(rendered).not_to have_selector('.js-note-edit')

    expect(rendered).not_to have_button('Edit comment')
  end
end
