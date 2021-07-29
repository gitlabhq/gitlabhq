# frozen_string_literal: true

RSpec.shared_examples 'issuable notes filter' do
  let(:params) do
    if issuable_parent.is_a?(Project)
      { namespace_id: issuable_parent.namespace, project_id: issuable_parent, id: issuable.iid }
    else
      { group_id: issuable_parent, id: issuable.to_param }
    end
  end

  it 'sets discussion filter' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    get :discussions, params: params.merge(notes_filter: notes_filter)

    expect(user.reload.notes_filter_for(issuable)).to eq(notes_filter)
    expect(UserPreference.count).to eq(1)
  end

  it 'expires notes e-tag cache for issuable if filter changed' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    expect_any_instance_of(issuable.class).to receive(:expire_note_etag_cache)

    get :discussions, params: params.merge(notes_filter: notes_filter)
  end

  it 'does not expires notes e-tag cache for issuable if filter did not change' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]
    user.set_notes_filter(notes_filter, issuable)

    expect_any_instance_of(issuable.class).not_to receive(:expire_note_etag_cache)

    get :discussions, params: params.merge(notes_filter: notes_filter)
  end

  it 'does not set notes filter when database is in read-only mode' do
    allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    get :discussions, params: params.merge(notes_filter: notes_filter)

    expect(user.reload.notes_filter_for(issuable)).to eq(UserPreference::NOTES_FILTERS[:all_notes])
  end

  it 'does not set notes filter when persist_filter param is false' do
    notes_filter = UserPreference::NOTES_FILTERS[:only_comments]

    get :discussions, params: params.merge(notes_filter: notes_filter, persist_filter: false)

    expect(user.reload.notes_filter_for(issuable)).to eq(UserPreference::NOTES_FILTERS[:all_notes])
  end

  it 'returns only user comments' do
    user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issuable)

    get :discussions, params: params
    discussions = json_response

    expect(discussions.count).to eq(1)
    expect(discussions.first["notes"].first["system"]).to be(false)
  end

  it 'returns only activity notes' do
    user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_activity], issuable)

    get :discussions, params: params
    discussions = json_response

    expect(discussions.count).to eq(1)
    expect(discussions.first["notes"].first["system"]).to be(true)
  end

  context 'when filter is set to "only_comments"' do
    it 'does not merge label event notes' do
      user.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issuable)

      expect(ResourceEvents::MergeIntoNotesService).not_to receive(:new)

      get :discussions, params: params
    end
  end
end
