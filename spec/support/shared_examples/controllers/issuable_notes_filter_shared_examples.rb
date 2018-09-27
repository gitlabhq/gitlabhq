shared_examples 'issuable notes filter' do
  it 'sets discussion filter' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    put :discussions, namespace_id: project.namespace, project_id: project, id: issuable.iid, notes_filter: notes_filter

    expect(user.reload.notes_filter_for(issuable)).to eq(notes_filter)
  end

  it 'does not set notes filter in GET requests' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    get :discussions, namespace_id: project.namespace, project_id: project, id: issuable.iid, notes_filter: notes_filter

    expect(user.reload.notes_filter_for(issuable)).to eq(0)
  end

  it 'returns no system note' do
    user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issuable)

    get :discussions, namespace_id: project.namespace, project_id: project, id: issuable.iid

    expect(JSON.parse(response.body).count).to eq(1)
  end
end
