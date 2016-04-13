require 'spec_helper'

describe API::Licenses, api: true  do
  include ApiHelpers

  describe 'Entity' do
    before { get api('/licenses/mit') }

    it { expect(json_response['key']).to eq('mit') }
    it { expect(json_response['name']).to eq('MIT License') }
    it { expect(json_response['nickname']).to be_nil }
    it { expect(json_response['popular']).to be true }
    it { expect(json_response['html_url']).to eq('http://choosealicense.com/licenses/mit/') }
    it { expect(json_response['source_url']).to eq('https://opensource.org/licenses/MIT') }
    it { expect(json_response['description']).to include('A permissive license that is short and to the point.') }
    it { expect(json_response['conditions']).to eq(%w[include-copyright]) }
    it { expect(json_response['permissions']).to eq(%w[commercial-use modifications distribution private-use]) }
    it { expect(json_response['limitations']).to eq(%w[no-liability]) }
    it { expect(json_response['content']).to include('The MIT License (MIT)') }
  end

  describe 'GET /licenses' do
    it 'returns a list of available license templates' do
      get api('/licenses')

      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(15)
      expect(json_response.map { |l| l['key'] }).to include('agpl-3.0')
    end

    describe 'the popular parameter' do
      context 'with popular=1' do
        it 'returns a list of available popular license templates' do
          get api('/licenses?popular=1')

          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
          expect(json_response.map { |l| l['key'] }).to include('apache-2.0')
        end
      end
    end
  end

  describe 'GET /licenses/:key' do
    context 'with :project and :fullname given' do
      before do
        get api("/licenses/#{license_type}?project=My+Awesome+Project&fullname=Anton+#{license_type.upcase}")
      end

      context 'for the mit license' do
        let(:license_type) { 'mit' }

        it 'returns the license text' do
          expect(json_response['content']).to include('The MIT License (MIT)')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('Copyright (c) 2016 Anton')
        end
      end

      context 'for the agpl-3.0 license' do
        let(:license_type) { 'agpl-3.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU AFFERO GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include('Copyright (C) 2016  Anton')
        end
      end

      context 'for the gpl-3.0 license' do
        let(:license_type) { 'gpl-3.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include('Copyright (C) 2016  Anton')
        end
      end

      context 'for the gpl-2.0 license' do
        let(:license_type) { 'gpl-2.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include('Copyright (C) 2016  Anton')
        end
      end

      context 'for the apache-2.0 license' do
        let(:license_type) { 'apache-2.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('Apache License')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('Copyright 2016 Anton')
        end
      end

      context 'for an uknown license' do
        let(:license_type) { 'muth-over9000' }

        it 'returns a 404' do
          expect(response.status).to eq(404)
        end
      end
    end

    context 'with no :fullname given' do
      context 'with an authenticated user' do
        let(:user) { create(:user) }

        it 'replaces the copyright owner placeholder with the name of the current user' do
          get api('/licenses/mit', user)

          expect(json_response['content']).to include("Copyright (c) 2016 #{user.name}")
        end
      end
    end
  end
end
