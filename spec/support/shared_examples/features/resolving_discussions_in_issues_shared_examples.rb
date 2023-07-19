# frozen_string_literal: true

RSpec.shared_examples 'creating an issue for a thread' do
  it 'shows an issue creation form' do
    # Title field is filled in
    title_field = page.find_field('issue[title]')
    expect(title_field.value).to include(merge_request.title)

    # Has a hidden field for the merge request
    merge_request_field = find('#merge_request_to_resolve_discussions_of', visible: false)
    expect(merge_request_field.value).to eq(merge_request.iid.to_s)

    # Has a mention of the discussion in the description
    description_field = page.find_field('issue[description]')
    expect(description_field.value).to include(discussion.first_note.note)
  end

  it 'creates a new issue for the project' do
    # Actually creates an issue for the project
    expect { click_button 'Create issue' }.to change { project.issues.reload.size }.by(1)

    # Resolves the discussion in the merge request
    discussion.first_note.reload
    expect(discussion.resolved?).to eq(true)

    # Issue title inludes MR title
    expect(page).to have_content(%(Follow-up from "#{merge_request.title}"))
  end
end
