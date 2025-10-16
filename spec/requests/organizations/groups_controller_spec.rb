# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }

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
        it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
      end

      context 'as an organization user' do
        let_it_be(:organization_user) { create(:organization_user, organization: organization, user: user) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
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

      it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'

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
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
        end

        context 'as a group owner' do
          before_all do
            group.add_owner(user)
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
        end

        context 'as a user that is not an owner' do
          it_behaves_like 'organization - not found response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
        end

        context 'as an organization owner' do
          let_it_be(:user) do
            organization_user = create(:organization_owner, organization: organization)
            organization_user.user
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
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
      it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
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
    let_it_be_with_reload(:group) { create(:group, organization: organization) }

    shared_examples 'marks the group for deletion' do
      specify do
        gitlab_request

        expect(group).to be_self_deletion_scheduled
      end
    end

    shared_examples 'does not mark the group for deletion' do
      specify do
        gitlab_request

        expect(group).not_to be_self_deletion_scheduled
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
          it_behaves_like 'does not mark the group for deletion'
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
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
          it_behaves_like 'marks the group for deletion'
        end

        context 'as a group owner' do
          before_all do
            group.add_owner(user)
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'

          context 'when mark for deletion succeeds' do
            it 'marks the group for delayed deletion' do
              expect { gitlab_request }.to change { group.reload.self_deletion_scheduled? }.from(false).to(true)
            end

            it 'does not immediately delete the group' do
              Sidekiq::Testing.fake! do
                expect { gitlab_request }.not_to change { GroupDestroyWorker.jobs.size }
              end
            end

            it 'schedules the group for deletion' do
              gitlab_request

              message = format("'%{group_name}' has been scheduled for deletion and will be deleted on",
                group_name: group.reload.name)
              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['message']).to include(message)
            end
          end

          context 'when mark for deletion fails' do
            let(:error) { 'error' }

            before do
              allow(::Groups::MarkForDeletionService).to receive_message_chain(:new, :execute)
                                                           .and_return(ServiceResponse.error(message: error))
            end

            it 'does not mark the group for deletion' do
              expect { gitlab_request }.not_to change { group.reload.self_deletion_scheduled? }.from(false)
            end

            it 'renders the error' do
              gitlab_request

              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(json_response['message']).to include(error)
            end
          end

          context 'when group is already marked for deletion' do
            before do
              create(:group_deletion_schedule, group: group)
            end

            context 'when permanently_remove param is set' do
              let(:params) { { permanently_remove: true } }

              subject(:gitlab_request) do
                delete groups_organization_path(organization, id: group.to_param), params: params, as: :json
              end

              describe 'when the :allow_immediate_namespaces_deletion application setting is false' do
                before do
                  stub_application_setting(allow_immediate_namespaces_deletion: false)
                end

                it 'returns error' do
                  Sidekiq::Testing.fake! do
                    expect { gitlab_request }.not_to change { GroupDestroyWorker.jobs.size }
                  end

                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end

              it 'deletes the group immediately' do
                expect(GroupDestroyWorker).to receive(:perform_async)

                gitlab_request

                expect(response).to have_gitlab_http_status(:ok)
                expect(json_response['message']).to include "Group '#{group.name}' is being deleted."
              end
            end

            context 'when permanently_remove param is not set' do
              it 'does nothing' do
                gitlab_request

                expect(response).to have_gitlab_http_status(:unprocessable_entity)
                expect(json_response['message']).to include "Group has already been marked for deletion"
              end
            end
          end
        end

        context 'as a user that is not an owner' do
          it_behaves_like 'organization - not found response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
          it_behaves_like 'does not mark the group for deletion'
        end

        context 'as an organization owner' do
          let_it_be(:user) do
            organization_user = create(:organization_owner, organization: organization)
            organization_user.user
          end

          it_behaves_like 'organization - successful response'
          it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
          it_behaves_like 'marks the group for deletion'
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
      it_behaves_like 'organization - action disabled by ui_for_organizations_enabled?'
      it_behaves_like 'does not mark the group for deletion'
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
        it_behaves_like 'does not mark the group for deletion'
      end
    end
  end
end
