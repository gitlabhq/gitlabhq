# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Asset proxy settings initialization' do
  describe '#asset_proxy' do
    it 'defaults to disabled' do
      expect(Banzai::Filter::AssetProxyFilter).to receive(:initialize_settings)

      require_relative '../../config/initializers/asset_proxy_settings'

      expect(Gitlab.config.asset_proxy.enabled).to be_falsey
    end
  end
end
