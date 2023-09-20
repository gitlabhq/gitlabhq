# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ViteHelper, feature_category: :tooling do
  let(:source) { 'foo.js' }
  let(:vite_source) { 'vite/foo.js' }
  let(:vite_tag) { '<tag src="vite/foo"></tag>' }
  let(:webpack_source) { 'webpack/foo.js' }
  let(:webpack_tag) { '<tag src="webpack/foo"></tag>' }

  context 'when vite enabled' do
    before do
      stub_rails_env('development')
      stub_feature_flags(vite: true)

      allow(helper).to receive(:vite_javascript_tag).and_return(vite_tag)
      allow(helper).to receive(:vite_asset_path).and_return(vite_source)
      allow(helper).to receive(:vite_stylesheet_tag).and_return(vite_tag)
      allow(helper).to receive(:vite_asset_url).and_return(vite_source)
      allow(helper).to receive(:vite_running).and_return(true)
    end

    describe '#universal_javascript_include_tag' do
      it 'returns vite javascript tag' do
        expect(helper.universal_javascript_include_tag(source)).to eq(vite_tag)
      end
    end

    describe '#universal_asset_path' do
      it 'returns vite asset path' do
        expect(helper.universal_asset_path(source)).to eq(vite_source)
      end
    end
  end

  context 'when vite disabled' do
    before do
      stub_feature_flags(vite: false)

      allow(helper).to receive(:javascript_include_tag).and_return(webpack_tag)
      allow(helper).to receive(:asset_path).and_return(webpack_source)
      allow(helper).to receive(:stylesheet_link_tag).and_return(webpack_tag)
      allow(helper).to receive(:path_to_stylesheet).and_return(webpack_source)
    end

    describe '#universal_javascript_include_tag' do
      it 'returns webpack javascript tag' do
        expect(helper.universal_javascript_include_tag(source)).to eq(webpack_tag)
      end
    end

    describe '#universal_asset_path' do
      it 'returns ActionView asset path' do
        expect(helper.universal_asset_path(source)).to eq(webpack_source)
      end
    end
  end
end
