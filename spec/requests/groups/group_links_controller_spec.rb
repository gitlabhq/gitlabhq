# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinksController, feature_category: :groups_and_projects do
  let_it_be(:shared_with_group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  before_all do
    shared_group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  describe 'DELETE #destroy' do
    let_it_be_with_reload(:link) do
      create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_group)
    end

    subject(:destroy_group_link) do
      delete group_group_link_path(shared_group, link.id)
    end

    context 'when the shared group has LDAP sync enabled' do
      before do
        allow_next_found_instance_of(Group) do |found_group|
          allow(found_group).to receive(:ldap_synced?).and_return(true)
        end
      end

      it 'still allows the group owner to remove the group-to-group share link' do
        expect { destroy_group_link }.to change { GroupGroupLink.count }.by(-1)

        expect(response).to have_gitlab_http_status(:found)
      end

      it 'still allows the group owner to remove it via the :js format' do
        delete group_group_link_path(shared_group, link.id, format: :js)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the service fails to destroy the link' do
      before do
        allow_next_instance_of(Groups::GroupLinks::DestroyService) do |service|
          allow(service).to receive(:execute).and_return({ status: :error, message: 'Not Found', http_status: 404 })
        end
      end

      it 'does not report success on the :js format' do
        delete group_group_link_path(shared_group, link.id, format: :js)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'redirects with an alert on the :html format' do
        destroy_group_link

        expect(response).to redirect_to(group_group_members_path(shared_group))
        expect(flash[:alert]).to eq('The group link could not be removed.')
      end
    end
  end
end
