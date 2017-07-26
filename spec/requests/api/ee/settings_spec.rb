require 'spec_helper'

describe API::Settings, 'EE Settings' do # rubocop:disable RSpec/FilePath
  include StubENV

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe "PUT /application/settings" do
    it 'sets EE specific settings' do
      put api("/application/settings", admin), help_text: 'Help text'

      expect(response).to have_http_status(200)
      expect(json_response['help_text']).to eq('Help text')
    end
  end

  context 'when the repository mirrors feature is not available' do
    before do
      stub_licensed_features(repository_mirrors: false)
      get api("/application/settings", admin)
    end

    it 'hides repository mirror attributes when the feature is available' do
      get api("/application/settings", admin)

      expect(response).to have_http_status(200)
      expect(json_response.keys).not_to include('mirror_max_capacity')
    end

    it 'does not update repository mirror attributes' do
      expect { put api("/application/settings", admin), mirror_max_capacity: 15 }
        .not_to change(ApplicationSetting.current.reload, :mirror_max_capacity)
    end
  end

  context 'when the repository mirrors feature is available' do
    before do
      stub_licensed_features(repository_mirrors: true)
    end

    it 'has repository mirror attributes when the feature is available' do
      get api("/application/settings", admin)

      expect(response).to have_http_status(200)
      expect(json_response.keys).to include('mirror_max_capacity')
    end

    it 'updates repository mirror attributes' do
      put api("/application/settings", admin), mirror_max_capacity: 15

      expect(ApplicationSetting.current.reload.mirror_max_capacity).to eq(15)
    end
  end
end
