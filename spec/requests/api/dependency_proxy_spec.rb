# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DependencyProxy, :api, :with_current_organization, feature_category: :virtual_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:blob) { create(:dependency_proxy_blob) }
  let_it_be_with_reload(:group) { blob.group }

  before do
    group.add_owner(user) # -- Does not work in before_all
    stub_config(dependency_proxy: { enabled: true })
    stub_last_activity_update
  end

  describe 'DELETE /groups/:id/dependency_proxy/cache' do
    subject { delete api("/groups/#{group_id}/dependency_proxy/cache", user) }

    shared_examples 'responding to purge requests' do
      context 'with feature available and enabled' do
        context 'an admin user' do
          it 'deletes the blobs and returns no content' do
            expect(PurgeDependencyProxyCacheWorker).to receive(:perform_async)

            subject

            expect(response).to have_gitlab_http_status(:accepted)
            expect(response.body).to eq('202')
          end
        end

        context 'a non-admin' do
          let(:user) { create(:user) }

          before do
            group.add_maintainer(user) # -- Does not work in before_all
          end

          it_behaves_like 'returning response status', :forbidden
        end
      end

      context 'depencency proxy is not enabled in the config' do
        before do
          stub_config(dependency_proxy: { enabled: false })
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with a group id' do
      let(:group_id) { group.id }

      it_behaves_like 'responding to purge requests'
    end

    context 'with an url encoded group id' do
      let(:group_id) { ERB::Util.url_encode(group.full_path) }

      it_behaves_like 'responding to purge requests'
    end

    it_behaves_like 'authorizing granular token permissions', :purge_dependency_proxy_cache do
      let(:boundary_object) { group }
      let(:request) do
        delete api("/groups/#{group.id}/dependency_proxy/cache", personal_access_token: pat)
      end
    end

    context 'when current organization differs from the group organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:other_group) { create(:group, :private, organization: other_organization) }

      before_all do
        other_group.add_owner(user)
      end

      before do
        current_organization.mark_as_isolated!
      end

      it 'denies access for numeric id' do
        delete api("/groups/#{other_group.id}/dependency_proxy/cache", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'denies access for url-encoded path id' do
        delete api("/groups/#{ERB::Util.url_encode(other_group.full_path)}/dependency_proxy/cache", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
