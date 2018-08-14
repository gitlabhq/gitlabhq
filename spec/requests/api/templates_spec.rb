require 'spec_helper'

describe API::Templates do
  context 'the Template Entity' do
    before do
      get api('/templates/gitignores/Ruby')
    end

    it { expect(json_response['name']).to eq('Ruby') }
    it { expect(json_response['content']).to include('*.gem') }
  end

  context 'the TemplateList Entity' do
    before do
      get api('/templates/gitignores')
    end

    it { expect(json_response.first['name']).not_to be_nil }
    it { expect(json_response.first['content']).to be_nil }
  end

  context 'requesting gitignores' do
    it 'returns a list of available gitignore templates' do
      get api('/templates/gitignores')

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to be > 15
    end
  end

  context 'requesting gitlab-ci-ymls' do
    it 'returns a list of available gitlab_ci_ymls' do
      get api('/templates/gitlab_ci_ymls')

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['name']).not_to be_nil
    end
  end

  context 'requesting gitlab-ci-yml for Ruby' do
    it 'adds a disclaimer on the top' do
      get api('/templates/gitlab_ci_ymls/Ruby')

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['content']).to start_with("# This file is a template,")
    end
  end

  context 'the License Template Entity' do
    before do
      get api('/templates/licenses/mit')
    end

    it 'returns a license template' do
      expect(json_response['key']).to eq('mit')
      expect(json_response['name']).to eq('MIT License')
      expect(json_response['nickname']).to be_nil
      expect(json_response['popular']).to be true
      expect(json_response['html_url']).to eq('http://choosealicense.com/licenses/mit/')
      expect(json_response['source_url']).to eq('https://opensource.org/licenses/MIT')
      expect(json_response['description']).to include('A short and simple permissive license with conditions')
      expect(json_response['conditions']).to eq(%w[include-copyright])
      expect(json_response['permissions']).to eq(%w[commercial-use modifications distribution private-use])
      expect(json_response['limitations']).to eq(%w[liability warranty])
      expect(json_response['content']).to include('MIT License')
    end
  end

  context 'GET templates/licenses' do
    it 'returns a list of available license templates' do
      get api('/templates/licenses')

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(12)
      expect(json_response.map { |l| l['key'] }).to include('agpl-3.0')
    end

    describe 'the popular parameter' do
      context 'with popular=1' do
        it 'returns a list of available popular license templates' do
          get api('/templates/licenses?popular=1')

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
          expect(json_response.map { |l| l['key'] }).to include('apache-2.0')
        end
      end
    end
  end

  context 'GET templates/licenses/:name' do
    context 'with :project and :fullname given' do
      before do
        get api("/templates/licenses/#{license_type}?project=My+Awesome+Project&fullname=Anton+#{license_type.upcase}")
      end

      context 'for the mit license' do
        let(:license_type) { 'mit' }

        it 'returns the license text' do
          expect(json_response['content']).to include('MIT License')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include("Copyright (c) #{Time.now.year} Anton")
        end
      end

      context 'for the agpl-3.0 license' do
        let(:license_type) { 'agpl-3.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU AFFERO GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include("Copyright (C) #{Time.now.year}  Anton")
        end
      end

      context 'for the gpl-3.0 license' do
        let(:license_type) { 'gpl-3.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include("Copyright (C) #{Time.now.year}  Anton")
        end
      end

      context 'for the gpl-2.0 license' do
        let(:license_type) { 'gpl-2.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('GNU GENERAL PUBLIC LICENSE')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include('My Awesome Project')
          expect(json_response['content']).to include("Copyright (C) #{Time.now.year}  Anton")
        end
      end

      context 'for the apache-2.0 license' do
        let(:license_type) { 'apache-2.0' }

        it 'returns the license text' do
          expect(json_response['content']).to include('Apache License')
        end

        it 'replaces placeholder values' do
          expect(json_response['content']).to include("Copyright #{Time.now.year} Anton")
        end
      end

      context 'for an uknown license' do
        let(:license_type) { 'muth-over9000' }

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with no :fullname given' do
      context 'with an authenticated user' do
        let(:user) { create(:user) }

        it 'replaces the copyright owner placeholder with the name of the current user' do
          get api('/templates/licenses/mit', user)

          expect(json_response['content']).to include("Copyright (c) #{Time.now.year} #{user.name}")
        end
      end
    end
  end
end
