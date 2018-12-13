shared_examples 'set sort order from user preference' do
  describe '#set_sort_order_from_user_preference' do
    # There is no issuable_sorting_field defined in any CE controllers yet,
    # however any other field present in user_preferences table can be used for testing.
    let(:sorting_field) { :issue_notes_filter }
    let(:sorting_param) { 'any' }

    before do
      allow(controller).to receive(:issuable_sorting_field).and_return(sorting_field)
    end

    context 'when database is in read-only mode' do
      it 'it does not update user preference' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)

        expect_any_instance_of(UserPreference).not_to receive(:update_attribute).with(sorting_field, sorting_param)

        get :index, namespace_id: project.namespace, project_id: project, sort: sorting_param
      end
    end

    context 'when database is not in read-only mode' do
      it 'updates user preference' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(false)

        expect_any_instance_of(UserPreference).to receive(:update_attribute).with(sorting_field, sorting_param)

        get :index, namespace_id: project.namespace, project_id: project, sort: sorting_param
      end
    end
  end
end
