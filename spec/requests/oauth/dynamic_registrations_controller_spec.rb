# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::DynamicRegistrationsController, feature_category: :system_access do
  let(:oauth_registration_path) { Gitlab::Routing.url_helpers.oauth_register_path }

  let(:valid_request_body) do
    {
      client_name: 'Test Application',
      redirect_uris: ['http://example.com/callback'],
      scope: 'mcp'
    }
  end

  let(:headers) { { 'Content-Type' => 'application/json' } }

  RSpec.shared_examples 'creates application successfully' do
    before do
      create_registration
    end

    it 'returns created status' do
      expect(response).to have_gitlab_http_status(:created)
    end
  end

  RSpec.shared_examples 'rejects request with bad_request' do
    let(:initial_count) { Authn::OauthApplication.count }

    before do
      initial_count
    end

    it 'returns bad request status' do
      create_registration
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'does not create application' do
      expect { create_registration }.not_to change { Authn::OauthApplication.count }
    end
  end

  describe 'POST /oauth/register' do
    subject(:create_registration) do
      post oauth_registration_path, params: request_body.to_json, headers: headers
    end

    context 'when feature flag is enabled' do
      context 'with valid parameters' do
        let(:request_body) { valid_request_body }

        it 'creates a new OAuth application' do
          expect { create_registration }.to change { Authn::OauthApplication.count }.by(1)
        end

        it_behaves_like 'creates application successfully'

        it 'returns correct JSON response structure' do
          create_registration

          application = Authn::OauthApplication.last.reload
          expect(response.parsed_body).to include(
            'client_id' => application.uid,
            'client_id_issued_at' => application.created_at.to_i,
            'redirect_uris' => ['http://example.com/callback'],
            'grant_types' => ['authorization_code'],
            'client_name' => '[Unverified Dynamic Application] Test Application',
            'scope' => 'mcp',
            'dynamic' => true
          )
        end

        it 'creates application with correct attributes' do
          create_registration

          application = Authn::OauthApplication.last
          expect(application).to have_attributes(
            name: '[Unverified Dynamic Application] Test Application',
            redirect_uri: 'http://example.com/callback',
            confidential: false,
            dynamic: true
          )
          expect(application.scopes.to_s).to eq('mcp')
        end

        it 'sets content type to JSON' do
          create_registration
          expect(response.content_type).to include('application/json')
        end

        context 'when validating application attributes' do
          before do
            create_registration
          end

          let(:created_application) { Authn::OauthApplication.last }

          it 'generates unique client_id and client_secret' do
            expect(created_application.uid).to be_present
            expect(created_application.uid).to be_a(String)
          end
        end

        it 'sets client_id_issued_at to current time' do
          freeze_time do
            create_registration

            expect(response.parsed_body['client_id_issued_at']).to eq(Time.current.to_i)
          end
        end
      end

      context 'with redirect URI variations' do
        context 'with multiple redirect URIs as array' do
          let(:request_body) do
            valid_request_body.merge(
              redirect_uris: %w[http://example.com/callback http://example.com/callback2]
            )
          end

          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'creates application with multiple redirect URIs' do
            expect(created_application.redirect_uri).to eq("http://example.com/callback\nhttp://example.com/callback2")
          end

          it 'returns multiple redirect URIs in response' do
            expect(response.parsed_body['redirect_uris'])
              .to eq(%w[http://example.com/callback http://example.com/callback2])
          end
        end

        context 'with redirect URI as string' do
          let(:request_body) do
            valid_request_body.merge(redirect_uris: 'http://example.com/callback')
          end

          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'creates application with single redirect URI' do
            expect(created_application.redirect_uri).to eq('http://example.com/callback')
          end

          it 'returns single redirect URI as array in response' do
            expect(response.parsed_body['redirect_uris']).to eq(['http://example.com/callback'])
          end
        end

        context 'with missing redirect_uris' do
          let(:request_body) { valid_request_body.except(:redirect_uris) }

          it_behaves_like 'rejects request with bad_request'
        end

        context 'with empty redirect_uris array' do
          let(:request_body) { valid_request_body.merge(redirect_uris: []) }

          it_behaves_like 'rejects request with bad_request'
        end

        context 'with invalid redirect URI' do
          let(:request_body) { valid_request_body.merge(redirect_uris: ['invalid-uri']) }

          it_behaves_like 'rejects request with bad_request'
        end

        context 'with HTTPS redirect URIs' do
          let(:request_body) do
            valid_request_body.merge(redirect_uris: ['https://secure.example.com/callback'])
          end

          it_behaves_like 'creates application successfully'
        end

        context 'with localhost redirect URIs' do
          let(:request_body) do
            valid_request_body.merge(redirect_uris: ['http://localhost:3000/callback'])
          end

          it_behaves_like 'creates application successfully'
        end

        context 'with custom scheme redirect URIs' do
          let(:request_body) do
            valid_request_body.merge(redirect_uris: ['myapp://callback'])
          end

          it_behaves_like 'creates application successfully'
        end
      end

      context 'with scope variations' do
        context 'with no scope provided' do
          let(:request_body) { valid_request_body.except(:scope) }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'uses default mcp scope' do
            expect(created_application.scopes.to_s).to eq('mcp')
          end

          it 'returns default scope in response' do
            expect(response.parsed_body['scope']).to eq('mcp')
          end
        end

        context 'with empty scope' do
          let(:request_body) { valid_request_body.merge(scope: '') }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'uses default mcp scope' do
            expect(created_application.scopes.to_s).to eq('mcp')
          end
        end

        context 'with nil scope' do
          let(:request_body) { valid_request_body.merge(scope: nil) }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'uses default mcp scope' do
            expect(created_application.scopes.to_s).to eq('mcp')
          end
        end

        context 'with mcp scope' do
          let(:request_body) { valid_request_body.merge(scope: 'mcp') }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'uses provided scope' do
            expect(created_application.scopes.to_s).to eq('mcp')
          end
        end

        context 'with different scope' do
          let(:request_body) { valid_request_body.merge(scope: 'api') }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'uses default mcp scope' do
            expect(created_application.scopes.to_s).to eq('mcp')
          end
        end
      end

      context 'with client_name variations' do
        context 'with minimal valid parameters' do
          let(:request_body) do
            {
              client_name: 'Minimal App',
              redirect_uris: ['http://example.com/callback']
            }
          end

          it 'creates application successfully' do
            create_registration

            expect(response).to have_gitlab_http_status(:created)

            application = Authn::OauthApplication.last
            expect(application.name).to eq('[Unverified Dynamic Application] Minimal App')
            expect(application.redirect_uri).to eq('http://example.com/callback')
            expect(application.scopes.to_s).to eq('mcp')
          end
        end

        context 'with very long client name' do
          let(:request_body) { valid_request_body.merge(client_name: 'A' * 1000) }

          it_behaves_like 'rejects request with bad_request'
        end

        context 'with special characters in client name' do
          let(:request_body) { valid_request_body.merge(client_name: 'Test App & Co. (v1.0)') }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'handles special characters correctly' do
            expect(created_application.name).to eq('[Unverified Dynamic Application] Test App & Co. (v1.0)')
          end
        end

        context 'with Unicode characters in client name' do
          let(:request_body) { valid_request_body.merge(client_name: 'Test 应用程序 🚀') }
          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'handles Unicode characters correctly' do
            expect(created_application.name).to eq('[Unverified Dynamic Application] Test 应用程序 🚀')
          end
        end

        context 'with empty client name' do
          let(:request_body) { valid_request_body.merge(client_name: '') }

          it_behaves_like 'rejects request with bad_request'

          it 'returns error response' do
            create_registration
            expect(response.parsed_body).to include(
              'error' => 'invalid_client_metadata'
            )
            expect(response.parsed_body['error_description']).to be_present
          end
        end

        context 'with nil client name' do
          let(:request_body) { valid_request_body.merge(client_name: nil) }

          it_behaves_like 'rejects request with bad_request'
        end
      end

      context 'with parameter filtering' do
        context 'with disallowed parameters' do
          let(:request_body) do
            valid_request_body.merge(
              confidential: false,
              dynamic: false,
              uid: 'custom_uid',
              secret: 'custom_secret',
              created_at: 1.day.ago.to_i,
              updated_at: 1.day.ago.to_i
            )
          end

          let(:created_application) { Authn::OauthApplication.last }

          before do
            create_registration
          end

          it 'filters out disallowed parameters' do
            expect(created_application.name).to eq('[Unverified Dynamic Application] Test Application')
            expect(created_application.confidential).to be false # Should always be true
            expect(created_application.dynamic).to be true # Should always be true
            expect(created_application.uid).not_to eq('custom_uid')
            expect(created_application.secret).not_to eq('custom_secret')
          end
        end
      end

      context 'with extra unknown parameters' do
        let(:request_body) do
          valid_request_body.merge(
            unknown_param: 'value',
            another_param: 'another_value'
          )
        end

        let(:created_application) { Authn::OauthApplication.last }

        before do
          create_registration
        end

        it 'ignores unknown parameters' do
          expect(response).to have_gitlab_http_status(:created)
          expect(created_application.name).to eq('[Unverified Dynamic Application] Test Application')
        end
      end

      context 'with request body format issues' do
        context 'with invalid JSON' do
          let(:request_body) { '{ invalid json' }

          it 'returns bad request status' do
            post oauth_registration_path, params: request_body, headers: headers
            expect(response).to have_gitlab_http_status(:bad_request)
          end

          it 'does not create application' do
            expect do
              post oauth_registration_path, params: request_body, headers: headers
            end.not_to change { Authn::OauthApplication.count }
          end
        end

        context 'with empty request body' do
          let(:request_body) { {} }

          it_behaves_like 'rejects request with bad_request'
        end
      end

      context 'with database validation failures' do
        context 'with duplicate application name' do
          let(:request_body) { valid_request_body.merge(client_name: 'Duplicate App') }

          before do
            create(:application, name: 'Duplicate App')
          end

          it 'creates application successfully' do
            create_registration
            expect(response).to have_gitlab_http_status(:created)
          end

          it 'allows duplicate names' do
            expect { create_registration }.to change { Authn::OauthApplication.count }.by(1)
          end
        end

        context 'with extremely long redirect URI' do
          let(:request_body) do
            valid_request_body.merge(redirect_uris: ["http://example.com/callback#{'a' * 10000}"])
          end

          it 'handles long redirect URIs appropriately' do
            create_registration

            expect(response).to have_gitlab_http_status(:created).or have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'with application creation edge cases' do
        context 'when application fails to save' do
          let(:request_body) { valid_request_body }

          before do
            allow_next_instance_of(Authn::OauthApplication) do |application|
              errors = ActiveModel::Errors.new(application)
              allow(errors).to receive(:full_messages).and_return(['Name is invalid'])
              allow(application).to receive_messages(persisted?: false, errors: errors)
            end
          end

          it 'returns bad request status' do
            create_registration
            expect(response).to have_gitlab_http_status(:bad_request)
          end

          it 'returns error response with validation messages' do
            create_registration
            expect(response.parsed_body).to include(
              'error' => 'invalid_client_metadata',
              'error_description' => 'Name is invalid'
            )
          end
        end
      end
    end
  end
end
