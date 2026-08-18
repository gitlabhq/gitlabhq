# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Observability::SessionsController, feature_category: :observability do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  let!(:observability_setting) do
    create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://o11y.example.com')
  end

  before do
    group.add_maintainer(user)
    sign_in(user)
    stub_feature_flags(observability_sass_features: group, observability_per_user_bff_auth: group)
  end

  describe 'POST #create' do
    subject(:make_request) { post group_observability_session_path(group) }

    it_behaves_like 'observability BFF session actions'
  end
end
