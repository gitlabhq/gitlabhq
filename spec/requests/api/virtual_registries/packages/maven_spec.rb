# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VirtualRegistries::Packages::Maven, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry, :with_upstream) }
  let_it_be(:project) { create(:project, namespace: registry.group) }
  let_it_be(:user) { project.creator }

  let(:upstream) { registry.upstream }

  describe 'GET /api/v4/virtual_registries/packages/maven/:id/*path' do
    let(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }
    let(:url) { "/virtual_registries/packages/maven/#{registry.id}/#{path}" }
    let(:service_response) do
      ServiceResponse.success(
        payload: { action: :workhorse_send_url,
                   action_params: { url: upstream.url_for(path), headers: upstream.headers } }
      )
    end

    let(:service_double) do
      instance_double(::VirtualRegistries::Packages::Maven::HandleFileRequestService, execute: service_response)
    end

    before do
      allow(::VirtualRegistries::Packages::Maven::HandleFileRequestService)
        .to receive(:new)
        .with(registry: registry, current_user: user, params: { path: path })
        .and_return(service_double)
      stub_config(dependency_proxy: { enabled: true }) # not enabled by default
    end

    subject(:request) do
      get api(url), headers: headers
    end

    shared_examples 'returning the workhorse send_url response' do
      it 'returns a workhorse send_url response' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('send-url:')
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Length'].to_i).to eq(0)
        expect(response.body).to eq('')

        send_data_type, send_data = workhorse_send_data

        expected_headers = upstream.headers.deep_stringify_keys.deep_transform_values do |value|
          [value]
        end

        expected_resp_headers = described_class::NO_BROWSER_EXECUTION_RESPONSE_HEADERS.deep_transform_values do |value|
          [value]
        end

        expect(send_data_type).to eq('send-url')
        expect(send_data['URL']).to be_present
        expect(send_data['AllowRedirects']).to be_truthy
        expect(send_data['DialTimeout']).to eq('10s')
        expect(send_data['ResponseHeaderTimeout']).to eq('10s')
        expect(send_data['ErrorResponseStatus']).to eq(502)
        expect(send_data['TimeoutResponseStatus']).to eq(504)
        expect(send_data['Header']).to eq(expected_headers)
        expect(send_data['ResponseHeaders']).to eq(expected_resp_headers)
      end
    end

    context 'for authentication' do
      context 'with a personal access token' do
        let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

        context 'when sent by headers' do
          let(:headers) { { 'Private-Token' => personal_access_token.token } }

          it_behaves_like 'returning the workhorse send_url response'
        end

        context 'when sent by basic auth' do
          let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

          it_behaves_like 'returning the workhorse send_url response'
        end
      end

      context 'with a deploy token' do
        let_it_be(:deploy_token) do
          create(:deploy_token, :group, groups: [registry.group], read_virtual_registry: true)
        end

        let_it_be(:user) { deploy_token }

        context 'when sent by headers' do
          let(:headers) { { 'Deploy-Token' => deploy_token.token } }

          it_behaves_like 'returning the workhorse send_url response'
        end

        context 'when sent by basic auth' do
          let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

          it_behaves_like 'returning the workhorse send_url response'
        end
      end

      context 'with ci job token' do
        let_it_be(:job) { create(:ci_build, user: user, status: :running, project: project) }

        context 'when sent by headers' do
          let(:headers) { { 'Job-Token' => job.token } }

          it_behaves_like 'returning the workhorse send_url response'
        end

        context 'when sent by basic auth' do
          let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token) }

          it_behaves_like 'returning the workhorse send_url response'
        end
      end
    end

    context 'with a valid user' do
      let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
      let(:headers) { { 'Private-Token' => personal_access_token.token } }

      context 'with service response errors' do
        where(:reason, :expected_status) do
          :path_not_present            | :bad_request
          :unauthorized                | :unauthorized
          :no_upstreams                | :bad_request
          :file_not_found_on_upstreams | :not_found
          :upstream_not_available      | :bad_request
        end

        with_them do
          let(:service_response) do
            ServiceResponse.error(message: 'error', reason: reason)
          end

          it "returns a #{params[:expected_status]} response" do
            request

            expect(response).to have_gitlab_http_status(expected_status)
            expect(response.body).to include('error') unless expected_status == :unauthorized
          end
        end
      end

      context 'with feature flag virtual_registry_maven disabled' do
        before do
          stub_feature_flags(virtual_registry_maven: false)
        end

        it_behaves_like 'returning response status', :not_found
      end

      context 'with a web browser' do
        described_class::MAJOR_BROWSERS.each do |browser|
          context "when accessing with a #{browser} browser" do
            before do
              allow_next_instance_of(::Browser) do |b|
                allow(b).to receive("#{browser}?").and_return(true)
              end
            end

            it 'returns a bad request response' do
              request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include(described_class::WEB_BROWSER_ERROR_MESSAGE)
            end
          end
        end
      end

      context 'with the dependency proxy disabled' do
        before do
          stub_config(dependency_proxy: { enabled: false })
        end

        it_behaves_like 'returning response status', :not_found
      end

      context 'as anonymous' do
        let(:headers) { {} }

        it_behaves_like 'returning response status', :unauthorized
      end
    end
  end
end
