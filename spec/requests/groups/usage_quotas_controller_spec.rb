# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UsageQuotasController, :with_license, feature_category: :consumables_cost_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:user) { create(:user) }

  subject(:request) { get group_usage_quotas_path(group) }

  before do
    sign_in(user)
  end

  describe 'GET /groups/*group_id/-/usage_quotas' do
    context 'when user has read_usage_quotas permission' do
      before do
        group.add_owner(user)
      end

      it 'renders index with 200 status code' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to match(/js-usage-quotas-view/)
          .and have_pushed_frontend_feature_flags(virtualRegistryMaven: true)
      end

      it 'renders 404 page if subgroup' do
        get group_usage_quotas_path(subgroup)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have read_usage_quotas permission' do
      before do
        group.add_maintainer(user)
      end

      it 'renders not_found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
