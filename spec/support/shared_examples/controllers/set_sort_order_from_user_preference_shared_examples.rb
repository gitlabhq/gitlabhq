# frozen_string_literal: true

RSpec.shared_examples 'set sort order from user preference' do
  describe '#set_sort_order_from_user_preference' do
    # There is no sorting_field defined in any CE controllers yet,
    # however any other field present in user_preferences table can be used for testing.

    context 'when database is in read-only mode' do
      it 'does not update user preference' do
        allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)

        expect_any_instance_of(UserPreference).not_to receive(:update).with({ controller.send(:sorting_field) => sorting_param })

        get :index, params: { namespace_id: project.namespace, project_id: project, sort: sorting_param }
      end
    end

    context 'when database is not in read-only mode' do
      it 'updates user preference' do
        allow(Gitlab::Database.main).to receive(:read_only?).and_return(false)

        expect_any_instance_of(UserPreference).to receive(:update).with({ controller.send(:sorting_field) => sorting_param })

        get :index, params: { namespace_id: project.namespace, project_id: project, sort: sorting_param }
      end
    end
  end
end
