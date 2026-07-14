# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubGroupsController, feature_category: :importers do
  describe 'GET status' do
    subject(:status) { get '/import/github_group/status', params: params, headers: headers }

    let_it_be(:user) { create(:user) }
    let(:headers) { { 'Accept' => 'application/json' } }
    let(:params) { {} }

    before do
      stub_application_setting(import_sources: ['github'])

      login_as(user)
    end

    context 'when OAuth config is missing' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
      end

      it 'returns missing config error' do
        status

        expect(json_response['errors']).to eq('Missing OAuth configuration for GitHub.')
      end
    end

    context 'when OAuth config present' do
      let(:github_access_token) { 'asdasd12345' }

      before do
        post '/import/github/personal_access_token', params: { personal_access_token: github_access_token }
      end

      it 'fetches organizations' do
        organizations = [
          {
            id: 1,
            login: "gitHub-organization",
            description: 'GitHub Organization'
          }
        ]
        stub_request(:get, "https://api.github.com/user/orgs?page=1&per_page=25")
         .to_return(status: 200, body: organizations.to_json, headers: { 'Content-Type' => 'application/json' })

        status

        expect(json_response).to eq({
          "provider_groups" => [
            {
              "name" => "gitHub-organization",
              "description" => "GitHub Organization"
            }
          ]
        })
      end

      context 'with pagination' do
        context 'when no page is specified' do
          it 'requests first page' do
            expect_next_instance_of(Octokit::Client) do |client|
              expect(client).to receive(:organizations).with(nil, { page: 1, per_page: 25 }).and_return([].to_enum)
            end

            status
          end
        end

        context 'when page is specified' do
          let(:params) { { page: 2 } }

          it 'responds with organizations with specified page' do
            expect_next_instance_of(Octokit::Client) do |client|
              expect(client).to receive(:organizations).with(nil, { page: 2, per_page: 25 }).and_return([].to_enum)
            end

            status
          end
        end
      end
    end
  end
end
