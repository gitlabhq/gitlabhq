require 'spec_helper'

describe API::Settings, 'EE Settings' do # rubocop:disable RSpec/FilePath
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "PUT /application/settings" do
    it 'sets EE specific settings' do
      put api("/application/settings", admin), help_text: 'Help text'

      expect(response).to have_http_status(200)
      expect(json_response['help_text']).to eq('Help text')
    end
  end
end
