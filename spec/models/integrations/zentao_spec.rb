# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Zentao do
  let(:url) { 'https://jihudemo.zentao.net' }
  let(:api_url) { 'https://jihudemo.zentao.net' }
  let(:api_token) { 'ZENTAO_TOKEN' }
  let(:zentao_product_xid) { '3' }
  let(:zentao_integration) { create(:zentao_integration) }

  describe '#create' do
    let(:project) { create(:project, :repository) }
    let(:params) do
      {
        project: project,
        url: url,
        api_url: api_url,
        api_token: api_token,
        zentao_product_xid: zentao_product_xid
      }
    end

    it 'stores data in data_fields correctly' do
      tracker_data = described_class.create!(params).zentao_tracker_data

      expect(tracker_data.url).to eq(url)
      expect(tracker_data.api_url).to eq(api_url)
      expect(tracker_data.api_token).to eq(api_token)
      expect(tracker_data.zentao_product_xid).to eq(zentao_product_xid)
    end
  end

  describe '#fields' do
    it 'returns custom fields' do
      expect(zentao_integration.fields.pluck(:name)).to eq(%w[url api_url api_token zentao_product_xid])
    end
  end

  describe '#test' do
    let(:test_response) { { success: true } }

    before do
      allow_next_instance_of(Gitlab::Zentao::Client) do |client|
        allow(client).to receive(:ping).and_return(test_response)
      end
    end

    it 'gets response from Gitlab::Zentao::Client#ping' do
      expect(zentao_integration.test).to eq(test_response)
    end
  end
end
