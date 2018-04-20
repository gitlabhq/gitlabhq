require 'spec_helper'

describe API::V3::Templates do
  shared_examples_for 'the Template Entity' do |path|
    before { get v3_api(path) }

    it { expect(json_response['name']).to eq('Ruby') }
    it { expect(json_response['content']).to include('*.gem') }
  end

  shared_examples_for 'the TemplateList Entity' do |path|
    before { get v3_api(path) }

    it { expect(json_response.first['name']).not_to be_nil }
    it { expect(json_response.first['content']).to be_nil }
  end

  shared_examples_for 'requesting gitignores' do |path|
    it 'returns a list of available gitignore templates' do
      get v3_api(path)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to be > 15
    end
  end

  shared_examples_for 'requesting gitlab-ci-ymls' do |path|
    it 'returns a list of available gitlab_ci_ymls' do
      get v3_api(path)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).not_to be_nil
    end
  end

  shared_examples_for 'requesting gitlab-ci-yml for Ruby' do |path|
    it 'adds a disclaimer on the top' do
      get v3_api(path)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['content']).to start_with("# This file is a template,")
    end
  end

  shared_examples_for 'the License Template Entity' do |path|
    before { get v3_api(path) }

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

  shared_examples_for 'GET licenses' do |path|
    it 'returns a list of available license templates' do
      get v3_api(path)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(12)
      expect(json_response.map { |l| l['key'] }).to include('agpl-3.0')
    end

    describe 'the popular parameter' do
      context 'with popular=1' do
        it 'returns a list of available popular license templates' do
          get v3_api("#{path}?popular=1")

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
          expect(json_response.map { |l| l['key'] }).to include('apache-2.0')
        end
      end
    end
  end

  shared_examples_for 'GET licenses/:name' do |path|
    context 'with :project and :fullname given' do
      before do
        get v3_api("#{path}/#{license_type}?project=My+Awesome+Project&fullname=Anton+#{license_type.upcase}")
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
          get v3_api('/templates/licenses/mit', user)

          expect(json_response['content']).to include("Copyright (c) #{Time.now.year} #{user.name}")
        end
      end
    end
  end

  describe 'with /templates namespace' do
    it_behaves_like 'the Template Entity', '/templates/gitignores/Ruby'
    it_behaves_like 'the TemplateList Entity', '/templates/gitignores'
    it_behaves_like 'requesting gitignores', '/templates/gitignores'
    it_behaves_like 'requesting gitlab-ci-ymls', '/templates/gitlab_ci_ymls'
    it_behaves_like 'requesting gitlab-ci-yml for Ruby', '/templates/gitlab_ci_ymls/Ruby'
    it_behaves_like 'the License Template Entity', '/templates/licenses/mit'
    it_behaves_like 'GET licenses', '/templates/licenses'
    it_behaves_like 'GET licenses/:name', '/templates/licenses'
  end

  describe 'without /templates namespace' do
    it_behaves_like 'the Template Entity', '/gitignores/Ruby'
    it_behaves_like 'the TemplateList Entity', '/gitignores'
    it_behaves_like 'requesting gitignores', '/gitignores'
    it_behaves_like 'requesting gitlab-ci-ymls', '/gitlab_ci_ymls'
    it_behaves_like 'requesting gitlab-ci-yml for Ruby', '/gitlab_ci_ymls/Ruby'
    it_behaves_like 'the License Template Entity', '/licenses/mit'
    it_behaves_like 'GET licenses', '/licenses'
    it_behaves_like 'GET licenses/:name', '/licenses'
  end
end
