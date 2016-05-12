require 'spec_helper'

describe API::Gitignores, api: true  do
  include ApiHelpers

  describe 'Entity Gitignore' do
    before { get api('/gitignores/Ruby') }

    it { expect(json_response['name']).to eq('Ruby') }
    it { expect(json_response['content']).to include('*.gem') }
  end

  describe 'Entity GitignoresList' do
    before { get api('/gitignores') }

    it { expect(json_response.first['name']).not_to be_nil }
    it { expect(json_response.first['content']).to be_nil }
  end

  describe 'GET /gitignores' do
    it 'returns a list of available license templates' do
      get api('/gitignores')

      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to be > 15
    end
  end
end
