# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  before do
    stub_feature_flags(downtier_delayed_deletion: false)
  end

  describe 'GET #new' do
    subject(:gitlab_request) { get new_groups_organization_path(organization) }

    context 'when the user is not signed in' do
      it_behaves_like 'organization - redirects to sign in page'

      context 'when `ui_for_organizations` feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it_behaves_like 'organization - redirects to sign in page'
      end
    end

    context 'when the user is signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        it_behaves_like 'organization - not found response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as an organization user' do
        let_it_be(:organization_user) { create(:organization_user, organization: organization, user: user) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  describe 'POST #create' do
    let_it_be(:params) { { group: { name: 'test-group', path: 'test-group' } } }
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { create(:organization) }

    subject(:gitlab_request) { post groups_organization_path(organization), params: params, as: :json }

    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'

      context 'when current user can create group inside the organization' do
        let_it_be(:organization_user) { create(:organization_user, organization: organization, user: user) }

        it 'returns the created group' do
          gitlab_request

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['path']).to eq('test-group')
        end
      end

      context 'when current user cannot create group inside the organization' do
        it 'returns the error' do
          gitlab_request

          permission_error_message = "You don't have permission to create a group in the provided organization."
          error = { "organization_id" => [permission_error_message] }
          expect(json_response['message']).to eq(error)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when the user is not signed in' do
      it 'returns unauthorized' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #edit' do
    let_it_be(:group) { create(:group, organization: organization) }

    context 'when group exists' do
      subject(:gitlab_request) do
        get edit_groups_organization_path(organization, id: group.to_param)
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'

        context 'when `ui_for_organizations` feature flag is disabled' do
          before do
            stub_feature_flags(ui_for_organizations: false)
          end

          it_behaves_like 'organization - redirects to sign in page'
        end
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        context 'as as admin', :enable_admin_mode do
          let_it_be(:user) { create(:admin) }

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end

        context 'as a group owner' do
          before_all do
            group.add_owner(user)
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end

        context 'as a user that is not an owner' do
          it_behaves_like 'organization - not found response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end

        context 'as an organization owner' do
          let_it_be(:user) do
            organization_user = create(:organization_owner, organization: organization)
            organization_user.user
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
        end
      end
    end

    context 'when group is not in organization' do
      let_it_be(:user) { create(:user) }
      let_it_be(:organization_2) { create(:organization) }

      subject(:gitlab_request) do
        get edit_groups_organization_path(organization_2, id: group.to_param)
      end

      before_all do
        group.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'organization - not found response'
      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
    end

    context 'when group does not exist' do
      subject(:gitlab_request) do
        get edit_groups_organization_path(organization, id: 'group-that-does-not-exist')
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        it_behaves_like 'organization - not found response'
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:group) { create(:group, organization: organization) }

    shared_examples 'deletes the group' do
      specify do
        expect_next_instance_of(Groups::DestroyService) do |instance|
          expect(instance).to receive(:async_execute)
        end

        gitlab_request
      end
    end

    shared_examples 'unable to delete the group' do
      specify do
        expect_any_instance_of(Groups::DestroyService) do |instance|
          expect(instance).not_to receive(:async_execute)
        end

        gitlab_request
      end
    end

    context 'when group exists' do
      subject(:gitlab_request) do
        delete groups_organization_path(organization, id: group.to_param)
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'

        context 'when `ui_for_organizations` feature flag is disabled' do
          before do
            stub_feature_flags(ui_for_organizations: false)
          end

          it_behaves_like 'organization - redirects to sign in page'
          it_behaves_like 'unable to delete the group'
        end
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        context 'as as admin', :enable_admin_mode do
          let_it_be(:user) { create(:admin) }

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
          it_behaves_like 'deletes the group'
        end

        context 'as a group owner' do
          before_all do
            group.add_owner(user)
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
          it_behaves_like 'deletes the group'

          context 'when destroy service raises DestroyError' do
            let(:error_message) { "Error deleting group" }

            before do
              allow_next_instance_of(Groups::DestroyService) do |instance|
                allow(instance).to receive(:async_execute)
                                     .and_raise(Groups::DestroyService::DestroyError, error_message)
              end
            end

            it 'returns the error message' do
              gitlab_request

              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(json_response['message']).to eq(error_message)
            end
          end

          context 'when delayed deletion feature is available' do
            before do
              stub_feature_flags(downtier_delayed_deletion: true)
            end

            context 'when mark for deletion succeeds' do
              it 'marks the group for delayed deletion' do
                expect { gitlab_request }.to change { group.reload.marked_for_deletion? }.from(false).to(true)
              end

              it 'does not immediately delete the group' do
                Sidekiq::Testing.fake! do
                  expect { gitlab_request }.not_to change { GroupDestroyWorker.jobs.size }
                end
              end

              it 'schedules the group for deletion' do
                gitlab_request

                message = format("'%{group_name}' has been scheduled for removal on", group_name: group.name)
                expect(response).to have_gitlab_http_status(:ok)
                expect(json_response['message']).to include(message)
              end
            end

            context 'when mark for deletion fails' do
              let(:error) { 'error' }

              before do
                allow(::Groups::MarkForDeletionService).to receive_message_chain(:new, :execute)
                                                             .and_return({ status: :error, message: error })
              end

              it 'does not mark the group for deletion' do
                expect { gitlab_request }.not_to change { group.reload.marked_for_deletion? }.from(false)
              end

              it 'renders the error' do
                gitlab_request

                expect(response).to have_gitlab_http_status(:unprocessable_entity)
                expect(json_response['message']).to include(error)
              end
            end

            context 'when group is already marked for deletion' do
              before do
                create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
              end

              context 'when permanently_remove param is set' do
                it 'deletes the group immediately' do
                  expect(GroupDestroyWorker).to receive(:perform_async)

                  delete groups_organization_path(organization, id: group.to_param, permanently_remove: true)

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(json_response['message']).to include "Group '#{group.name}' is being deleted."
                end
              end

              context 'when permanently_remove param is not set' do
                it 'does nothing' do
                  gitlab_request

                  expect(response).to have_gitlab_http_status(:unprocessable_entity)
                  expect(json_response['message']).to include "Group has been already marked for deletion"
                end
              end
            end
          end
        end

        context 'as a user that is not an owner' do
          it_behaves_like 'organization - not found response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
          it_behaves_like 'unable to delete the group'
        end

        context 'as an organization owner' do
          let_it_be(:user) do
            organization_user = create(:organization_owner, organization: organization)
            organization_user.user
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
          it_behaves_like 'deletes the group'
        end
      end
    end

    context 'when group is not in organization' do
      let_it_be(:user) { create(:user) }
      let_it_be(:organization_2) { create(:organization) }

      subject(:gitlab_request) do
        delete groups_organization_path(organization_2, id: group.to_param)
      end

      before_all do
        group.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'organization - not found response'
      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      it_behaves_like 'unable to delete the group'
    end

    context 'when group does not exist' do
      subject(:gitlab_request) do
        delete groups_organization_path(organization, id: 'group-that-does-not-exist')
      end

      context 'when the user is not signed in' do
        it_behaves_like 'organization - redirects to sign in page'
      end

      context 'when the user is signed in' do
        let_it_be(:user) { create(:user) }

        before do
          sign_in(user)
        end

        it_behaves_like 'organization - not found response'
        it_behaves_like 'unable to delete the group'
      end
    end
  end
end
