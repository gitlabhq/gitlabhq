require 'spec_helper'

describe 'Groups (JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:group) { create(:group, name: 'frontend-fixtures-group' )}

  render_views

  before(:all) do
    clean_frontend_fixtures('groups/')
  end

  before do
    group.add_master(admin)
    sign_in(admin)
  end

  describe Groups::Settings::CiCdController, '(JavaScript fixtures)', type: :controller do
    it 'groups/ci_cd_settings.html.raw' do |example|
      get :show,
        group_id: group

      expect(response).to be_success
      store_frontend_fixture(response, example.description)
    end
  end
end
