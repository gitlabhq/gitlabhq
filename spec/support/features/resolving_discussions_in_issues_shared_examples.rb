shared_examples 'creating an issue for a discussion' do
  it 'shows an issue with the title filled in' do
    title_field = page.find_field('issue[title]')

    expect(title_field.value).to include(merge_request.title)
  end

  it 'has a mention of the discussion in the description'  do
    description_field = page.find_field('issue[description]')

    expect(description_field.value).to include(discussion.first_note.note)
  end

  it 'can create a new issue for the project' do
    expect { click_button 'Submit issue' }.to change { project.issues.reload.size }.by(1)
  end

  it 'resolves the discussion in the merge request' do
    click_button 'Submit issue'

    discussion.first_note.reload

    expect(discussion.resolved?).to eq(true)
  end
end
