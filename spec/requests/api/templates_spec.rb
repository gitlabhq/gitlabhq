require 'spec_helper'

describe API::Templates, api: true  do
  include ApiHelpers

  describe 'the Template Entity' do
    before { get api('/gitignores/Ruby') }

    it { expect(json_response['name']).to eq('Ruby') }
    it { expect(json_response['content']).to include('*.gem') }
  end

  describe 'the TemplateList Entity' do
    before { get api('/gitignores') }

    it { expect(json_response.first['name']).not_to be_nil }
    it { expect(json_response.first['content']).to be_nil }
  end

  context 'requesting gitignores' do
    describe 'GET /gitignores' do
      it 'returns a list of available gitignore templates' do
        get api('/gitignores')

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to be > 15
      end
    end
  end

  context 'requesting gitlab-ci-ymls' do
    describe 'GET /gitlab_ci_ymls' do
      it 'returns a list of available gitlab_ci_ymls' do
        get api('/gitlab_ci_ymls')

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).not_to be_nil
      end
    end
  end

  describe 'GET /gitlab_ci_ymls/Ruby' do
    it 'adds a disclaimer on the top' do
      get api('/gitlab_ci_ymls/Ruby')

      expect(response).to have_http_status(200)
      expect(json_response['content']).to start_with("# This file is a template,")
    end
  end
end
