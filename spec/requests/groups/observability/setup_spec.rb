# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Groups::Observability::Setup", feature_category: :observability do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_developer(user)
  end

  before do
    sign_in(user)
  end

  shared_examples 'requires feature flag' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'returns 404' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'requires permissions' do
    context 'without proper permissions' do
      before do
        group.members.find_by(user: user).destroy!
      end

      it 'returns 403' do
        subject
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "GET /show" do
    subject(:get_setup_page) { get group_observability_setup_path(group) }

    include_examples 'requires feature flag'

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      it "returns http success and renders show template" do
        get_setup_page

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:success)
          expect(response).to render_template(:show)
        end
      end

      include_examples 'requires permissions'
    end
  end
end
