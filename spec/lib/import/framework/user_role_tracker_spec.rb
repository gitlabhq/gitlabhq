# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Framework::UserRoleTracker, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }

  let(:tracking_class_name) { 'SomeImporter' }
  let(:import_type) { 'some_import' }

  subject(:tracker) do
    described_class.new(
      current_user: current_user,
      tracking_class_name: tracking_class_name,
      import_type: import_type
    )
  end

  describe '#track' do
    context 'when destination_namespace is blank' do
      it 'tracks the event with Owner role' do
        tracker.track('')

        expect_snowplow_event(
          category: tracking_class_name,
          action: 'create',
          label: 'import_access_level',
          user: current_user,
          extra: { user_role: 'Owner', import_type: import_type }
        )
      end
    end

    context 'when destination_namespace does not exist' do
      it 'tracks the event with Owner role' do
        tracker.track('nonexistent/namespace')

        expect_snowplow_event(
          category: tracking_class_name,
          action: 'create',
          label: 'import_access_level',
          user: current_user,
          extra: { user_role: 'Owner', import_type: import_type }
        )
      end
    end

    context 'when destination_namespace is a user namespace' do
      let_it_be(:user_namespace) { create(:user_namespace) }

      it 'tracks the event with Owner role' do
        tracker.track(user_namespace.full_path)

        expect_snowplow_event(
          category: tracking_class_name,
          action: 'create',
          label: 'import_access_level',
          user: current_user,
          extra: { user_role: 'Owner', import_type: import_type }
        )
      end
    end

    context 'when destination_namespace is a group' do
      let_it_be(:group) { create(:group) }

      context 'when the user is not a member of the group' do
        it 'tracks the event with "Not a member" role' do
          tracker.track(group.full_path)

          expect_snowplow_event(
            category: tracking_class_name,
            action: 'create',
            label: 'import_access_level',
            user: current_user,
            extra: { user_role: 'Not a member', import_type: import_type }
          )
        end
      end

      context 'when the user is a member of the group' do
        it "tracks the event with the user's access level" do
          group.add_developer(current_user)

          tracker.track(group.full_path)

          expect_snowplow_event(
            category: tracking_class_name,
            action: 'create',
            label: 'import_access_level',
            user: current_user,
            extra: { user_role: 'Developer', import_type: import_type }
          )
        end
      end

      context 'when the user is an owner of the group' do
        it 'tracks the event with Owner role' do
          group.add_owner(current_user)

          tracker.track(group.full_path)

          expect_snowplow_event(
            category: tracking_class_name,
            action: 'create',
            label: 'import_access_level',
            user: current_user,
            extra: { user_role: 'Owner', import_type: import_type }
          )
        end
      end
    end
  end
end
