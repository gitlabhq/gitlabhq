# frozen_string_literal: true

require 'spec_helper'

require_relative '../concerns/membership_actions_shared_examples'

RSpec.describe Groups::GroupMembersController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:membershipable) { create(:group, :public) }

  let(:membershipable_path) { group_path(membershipable) }

  describe 'GET /groups/*group_id/-/group_members' do
    subject(:request) do
      get group_group_members_path(group_id: membershipable)
    end

    it 'pushes feature flag to frontend' do
      request

      expect(response.body).to have_pushed_frontend_feature_flags(importerUserMapping: true)
      expect(response.body).to have_pushed_frontend_feature_flags(serviceAccountsCrud: true)
    end
  end

  describe 'GET /groups/*group_id/-/group_members/request_access' do
    subject(:request) do
      get request_access_group_group_members_path(group_id: membershipable)
    end

    it_behaves_like 'request_accessable'
  end

  describe 'GET /groups/*group_id/-/group_members/bulk_reassignment_file' do
    let_it_be(:membershipable) do
      create(:group, :public).tap do |group|
        group.add_owner(user)
      end
    end

    subject(:request) do
      get bulk_reassignment_file_group_group_members_path(group_id: membershipable)
    end

    context 'when not signed in' do
      it 'forbids access to the endpoint' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'responds with CSV data' do
        request

        expect(response).to have_gitlab_http_status(:success)
      end

      context 'and the user is not a group owner' do
        let_it_be(:membershipable) { create(:group, :public) }

        it 'forbids access to the endpoint' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'and the CSV is not generated properly' do
        before do
          allow_next_instance_of(Import::SourceUsers::GenerateCsvService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'my error message'))
          end
        end

        it 'redirects with an error' do
          request

          expect(response).to be_redirect
          expect(flash[:alert]).to eq('my error message')
        end
      end

      context 'when :importer_user_mapping_reassignment_csv is disabled' do
        before do
          stub_feature_flags(importer_user_mapping_reassignment_csv: false)
        end

        it 'responds with 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
