shared_examples 'issuable notes filter' do
  it 'sets discussion filter' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    get :discussions, namespace_id: project.namespace, project_id: project, id: issuable.iid, notes_filter: notes_filter

    expect(user.reload.notes_filter_for(issuable)).to eq(notes_filter)
    expect(UserPreference.count).to eq(1)
  end

  it 'does not set notes filter when database is in read only mode' do
    allow(Gitlab::Database).to receive(:read_only?).and_return(true)
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
