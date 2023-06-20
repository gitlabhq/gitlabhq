# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Links::Params, feature_category: :release_orchestration do
  subject(:filter) { described_class.new(params) }

  let(:params) { { name: name, url: url, direct_asset_path: direct_asset_path, link_type: link_type, unknown: '?' } }
  let(:name) { 'link' }
  let(:url) { 'https://example.com' }
  let(:direct_asset_path) { '/path' }
  let(:link_type) { 'other' }

  describe '#allowed_params' do
    subject { filter.allowed_params }

    it 'returns only allowed params' do
      is_expected.to eq('name' => name, 'url' => url, 'filepath' => direct_asset_path, 'link_type' => link_type)
    end

    context 'when deprecated filepath is used' do
      let(:params) { super().merge(direct_asset_path: nil, filepath: 'filepath') }

      it 'uses filepath value' do
        is_expected.to eq('name' => name, 'url' => url, 'filepath' => 'filepath', 'link_type' => link_type)
      end
    end

    context 'when both direct_asset_path and filepath are provided' do
      let(:params) { super().merge(filepath: 'filepath') }

      it 'uses direct_asset_path value' do
        is_expected.to eq('name' => name, 'url' => url, 'filepath' => direct_asset_path, 'link_type' => link_type)
      end
    end
  end
end
