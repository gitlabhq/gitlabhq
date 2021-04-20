# frozen_string_literal: true

RSpec.shared_examples 'creating an issue for a thread' do
  it 'shows an issue with the title filled in' do
    title_field = page.find_field('issue[title]')

    expect(title_field.value).to include(merge_request.title)
  end

  it 'has a mention of the discussion in the description' do
    description_field = page.find_field('issue[description]')

    expect(description_field.value).to include(discussion.first_note.note)
  end

  it 'can create a new issue for the project' do
    expect { click_button 'Create issue' }.to change { project.issues.reload.size }.by(1)
  end

  it 'resolves the discussion in the merge request' do
    click_button 'Create issue'

    discussion.first_note.reload

    expect(discussion.resolved?).to eq(true)
  end

  it 'shows a flash messaage after resolving a discussion' do
    click_button 'Create issue'

    page.within '.flash-notice' do
      # Only check for the word 'Resolved' since the spec might have resolved
      # multiple discussions
      expect(page).to have_content('Resolved')
    end
  end

  it 'has a hidden field for the merge request' do
    merge_request_field = find('#merge_request_to_resolve_discussions_of', visible: false)

    expect(merge_request_field.value).to eq(merge_request.iid.to_s)
  end
end
