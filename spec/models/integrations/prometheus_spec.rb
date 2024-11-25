# frozen_string_literal: true

require 'spec_helper'

require 'googleauth'

RSpec.describe Integrations::Prometheus, :use_clean_rails_memory_store_caching, :snowplow, feature_category: :observability do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let_it_be_with_reload(:project) { create(:project, :with_prometheus_integration) }

  let(:integration) { project.prometheus_integration }

  it_behaves_like Integrations::Base::Monitoring

  context 'redirects' do
    it 'does not follow redirects' do
      redirect_to = 'https://redirected.example.com'
      redirect_req_stub = stub_prometheus_request(prometheus_query_url('1'), status: 302, headers: { location: redirect_to })
      redirected_req_stub = stub_prometheus_request(redirect_to, body: { status: 'success' })

      result = integration.test

      # result = { success: false, result: error }
      expect(result[:success]).to be_falsy
      expect(result[:result]).to be_instance_of(Gitlab::PrometheusClient::UnexpectedResponseError)

      expect(redirect_req_stub).to have_been_requested
      expect(redirected_req_stub).not_to have_been_requested
    end
  end

  describe 'Validations' do
    context 'when manual_configuration is enabled' do
      before do
        integration.manual_configuration = true
      end

      it 'does not validates presence of api_url' do
        expect(integration).not_to validate_presence_of(:api_url)
      end
    end

    context 'when manual configuration is disabled' do
      before do
        integration.manual_configuration = false
      end

      it 'does not validate presence of api_url' do
        expect(integration).not_to validate_presence_of(:api_url)
        expect(integration.valid?).to eq(true)
      end

      context 'local connections allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'does not validate presence of api_url' do
          expect(integration).not_to validate_presence_of(:api_url)
          expect(integration.valid?).to eq(true)
        end
      end
    end

    context 'when the api_url domain points to localhost or local network' do
      let(:domain) { Addressable::URI.parse(integration.api_url).hostname }

      it 'cannot query' do
        expect(integration.can_query?).to be true

        aggregate_failures do
          ['127.0.0.1', '192.168.2.3'].each do |url|
            allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([Addrinfo.tcp(url, 80)])

            expect(integration.can_query?).to be false
          end
        end
      end

      it 'can query when local requests are allowed' do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)

        aggregate_failures do
          ['127.0.0.1', '192.168.2.3'].each do |url|
            allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([Addrinfo.tcp(url, 80)])

            expect(integration.can_query?).to be true
          end
        end
      end
    end
  end

  describe '#test' do
    before do
      integration.manual_configuration = true
    end

    let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector')) }

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(integration.test[:result]).to eq('Checked API endpoint')
        expect(integration.test[:success]).to be_truthy
        expect(req_stub).to have_been_requested.twice
      end
    end

    context 'failure' do
      let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), status: 404) }

      it 'fails to read the discovery endpoint' do
        expect(integration.test[:success]).to be_falsy
        expect(req_stub).to have_been_requested
      end
    end

    context 'when configuration is not valid' do
      before do
        integration.manual_configuration = nil
      end

      it 'returns failure message' do
        expect(integration.test[:success]).to be_falsy
        expect(integration.test[:result]).to eq('Prometheus configuration error')
      end
    end
  end

  describe '#prometheus_client' do
    let(:api_url) { 'http://some_url' }

    before do
      integration.active = true
      integration.api_url = api_url
      integration.manual_configuration = manual_configuration
    end

    context 'manual configuration is enabled' do
      let(:manual_configuration) { true }

      it 'calls valid?' do
        allow(integration).to receive(:valid?).and_call_original

        expect(integration.prometheus_client).not_to be_nil

        expect(integration).to have_received(:valid?)
      end
    end

    context 'manual configuration is disabled' do
      let(:manual_configuration) { false }

      it 'no client provided' do
        expect(integration.prometheus_client).to be_nil
      end
    end

    context 'when local requests are allowed' do
      let(:manual_configuration) { true }
      let(:api_url) { 'http://192.168.1.1:9090' }

      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)

        stub_prometheus_request("#{api_url}/api/v1/query?query=1")
      end

      it 'allows local requests' do
        expect(integration.prometheus_client).not_to be_nil
        expect { integration.prometheus_client.ping }.not_to raise_error
      end
    end

    context 'when local requests are blocked' do
      let(:manual_configuration) { true }
      let(:api_url) { 'http://192.168.1.1:9090' }

      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

        stub_prometheus_request("#{api_url}/api/v1/query?query=1")
      end

      it 'blocks local requests' do
        expect(integration.prometheus_client).to be_nil
      end
    end

    context 'behind IAP' do
      let(:manual_configuration) { true }
      let(:google_iap_service_account_json) { Gitlab::Json.generate(google_iap_service_account) }

      let(:google_iap_service_account) do
        {
          type: "service_account",
          # dummy private key generated only for this test to pass openssl validation
          private_key: <<~KEY
            -----BEGIN RSA PRIVATE KEY-----
            MIIBOAIBAAJAU85LgUY5o6j6j/07GMLCNUcWJOBA1buZnNgKELayA6mSsHrIv31J
            Y8kS+9WzGPQninea7DcM4hHA7smMgQD1BwIDAQABAkAqKxMy6PL3tn7dFL43p0ex
            JyOtSmlVIiAZG1t1LXhE/uoLpYi5DnbYqGgu0oih+7nzLY/dXpNpXUmiRMOUEKmB
            AiEAoTi2rBXbrLSi2C+H7M/nTOjMQQDuZ8Wr4uWpKcjYJTMCIQCFEskL565oFl/7
            RRQVH+cARrAsAAoJSbrOBAvYZ0PI3QIgIEFwis10vgEF86rOzxppdIG/G+JL0IdD
            9IluZuXAGPECIGUo7qSaLr75o2VEEgwtAFH5aptIPFjrL5LFCKwtdB4RAiAYZgFV
            HCMmaooAw/eELuMoMWNYmujZ7VaAnOewGDW0uw==
            -----END RSA PRIVATE KEY-----
          KEY
        }
      end

      def stub_iap_request
        integration.google_iap_service_account_json = google_iap_service_account_json
        integration.google_iap_audience_client_id = 'IAP_CLIENT_ID.apps.googleusercontent.com'

        stub_request(:post, 'https://oauth2.googleapis.com/token')
          .to_return(
            status: 200,
            body: '{"id_token": "FOO"}',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' }
          )
      end

      it 'includes the authorization header' do
        stub_iap_request

        expect(integration.prometheus_client).not_to be_nil
        expect(integration.prometheus_client.send(:options)).to have_key(:headers)
        expect(integration.prometheus_client.send(:options)[:headers]).to eq(authorization: "Bearer FOO")
      end

      context 'with invalid IAP JSON' do
        let(:google_iap_service_account_json) { 'invalid json' }

        it 'does not include authorization header' do
          stub_iap_request

          expect(integration.prometheus_client).not_to be_nil
          expect(integration.prometheus_client.send(:options)).not_to have_key(:headers)
        end
      end

      context 'when passed with token_credential_uri', issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/284819' do
        let(:malicious_host) { 'http://example.com' }

        where(:param_name) do
          [
            :token_credential_uri,
            :tokencredentialuri,
            :Token_credential_uri,
            :tokenCredentialUri
          ]
        end

        with_them do
          it 'does not make any unexpected HTTP requests' do
            google_iap_service_account[param_name] = malicious_host
            stub_iap_request
            stub_request(:any, malicious_host).to_raise('Making additional HTTP requests is forbidden!')

            expect(integration.prometheus_client).not_to be_nil
          end
        end
      end
    end
  end

  describe '#prometheus_available?' do
    context 'clusters with enabled prometheus' do
      before do
        create(:clusters_integrations_prometheus, cluster: cluster)
      end

      context 'cluster belongs to project' do
        let_it_be(:cluster) { create(:cluster, projects: [project]) }

        it 'returns true' do
          expect(integration.prometheus_available?).to be(true)
        end
      end

      context 'cluster belongs to projects group' do
        let_it_be(:group) { create(:group) }

        let_it_be(:project) { create(:project, :with_prometheus_integration, group: group) }
        let_it_be(:cluster) { create(:cluster_for_group, groups: [group]) }

        it 'returns true' do
          expect(integration.prometheus_available?).to be(true)
        end

        it 'avoids N+1 queries' do
          integration
          5.times do |i|
            other_cluster = create(:cluster_for_group, groups: [group], environment_scope: i)
            create(:clusters_integrations_prometheus, cluster: other_cluster)
          end
          expect { integration.prometheus_available? }.not_to exceed_query_limit(1)
        end
      end

      context 'cluster belongs to gitlab instance' do
        let(:cluster) { create(:cluster, :instance) }

        it 'returns true' do
          expect(integration.prometheus_available?).to be(true)
        end
      end
    end

    context 'clusters with prometheus disabled' do
      let(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_integrations_prometheus, :disabled, cluster: cluster) }

      it 'returns false' do
        expect(integration.prometheus_available?).to be(false)
      end
    end

    context 'clusters without prometheus' do
      let(:cluster) { create(:cluster, projects: [project]) }

      it 'returns false' do
        expect(integration.prometheus_available?).to be(false)
      end
    end

    context 'no clusters' do
      it 'returns false' do
        expect(integration.prometheus_available?).to be(false)
      end
    end
  end

  describe '#synchronize_service_state before_save callback' do
    context 'no clusters with prometheus are installed' do
      context 'when integration is inactive' do
        before do
          integration.active = false
        end

        it 'activates integration when manual_configuration is enabled' do
          expect { integration.update!(manual_configuration: true) }.to change { integration.active }.from(false).to(true)
        end

        it 'keeps integration inactive when manual_configuration is disabled' do
          expect { integration.update!(manual_configuration: false) }.not_to change { integration.active }.from(false)
        end
      end

      context 'when integration is active' do
        before do
          integration.active = true
        end

        it 'keeps the integration active when manual_configuration is enabled' do
          expect { integration.update!(manual_configuration: true) }.not_to change { integration.active }.from(true)
        end

        it 'inactivates the integration when manual_configuration is disabled' do
          expect { integration.update!(manual_configuration: false) }.to change { integration.active }.from(true).to(false)
        end
      end
    end

    context 'with prometheus installed in the cluster' do
      before do
        allow(integration).to receive(:prometheus_available?).and_return(true)
      end

      context 'when integration is inactive' do
        before do
          integration.active = false
        end

        it 'activates integration when manual_configuration is enabled' do
          expect { integration.update!(manual_configuration: true) }.to change { integration.active }.from(false).to(true)
        end

        it 'activates integration when manual_configuration is disabled' do
          expect { integration.update!(manual_configuration: false) }.to change { integration.active }.from(false).to(true)
        end
      end

      context 'when integration is active' do
        before do
          integration.active = true
        end

        it 'keeps integration active when manual_configuration is enabled' do
          expect { integration.update!(manual_configuration: true) }.not_to change { integration.active }.from(true)
        end

        it 'keeps integration active when manual_configuration is disabled' do
          expect { integration.update!(manual_configuration: false) }.not_to change { integration.active }.from(true)
        end
      end
    end
  end

  describe '#track_events after_commit callback' do
    before do
      allow(integration).to receive(:prometheus_available?).and_return(true)
    end

    context "enabling manual_configuration" do
      it "tracks enable event" do
        integration.update!(manual_configuration: false)
        integration.update!(manual_configuration: true)

        expect_snowplow_event(category: 'cluster:services:prometheus', action: 'enabled_manual_prometheus')
      end

      it "tracks disable event" do
        integration.update!(manual_configuration: true)
        integration.update!(manual_configuration: false)

        expect_snowplow_event(category: 'cluster:services:prometheus', action: 'disabled_manual_prometheus')
      end
    end
  end

  describe '#sync_http_integration after_save callback' do
    context 'with corresponding HTTP integration' do
      let_it_be_with_reload(:http_integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }

      it 'syncs the attribute' do
        expect { integration.update!(manual_configuration: false) }
          .to change { http_integration.reload.active }
          .from(true).to(false)
      end

      context 'when changing a different attribute' do
        it 'does not sync the attribute or execute extra queries' do
          expect { integration.update!(api_url: 'https://any.url') }
            .to issue_fewer_queries_than { integration.update!(manual_configuration: false) }
        end
      end
    end

    context 'without corresponding HTTP integration' do
      let_it_be(:other_http_integration) { create(:alert_management_prometheus_integration, project: project) }

      it 'does not sync the attribute or execute extra queries' do
        expect { integration.update!(manual_configuration: false) }
          .not_to change { other_http_integration.reload.active }
      end
    end
  end

  describe '#editable?' do
    it 'is editable' do
      expect(integration.editable?).to be(true)
    end

    context 'when cluster exists with prometheus enabled' do
      let(:cluster) { create(:cluster, projects: [project]) }

      before do
        integration.update!(manual_configuration: false)

        create(:clusters_integrations_prometheus, cluster: cluster)
      end

      it 'remains editable' do
        expect(integration.editable?).to be(true)
      end
    end
  end

  describe '#google_iap_service_account_json' do
    subject(:iap_details) { integration.google_iap_service_account_json }

    before do
      integration.google_iap_service_account_json = value
    end

    context 'with valid JSON' do
      let(:masked_value) { described_class::MASKED_VALUE }
      let(:json) { Gitlab::Json.parse(iap_details) }

      let(:value) do
        Gitlab::Json.generate({
          type: 'service_account',
          private_key: 'SECRET',
          foo: 'secret',
          nested: {
            key: 'value'
          }
        })
      end

      it 'masks all JSON values', issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/384580' do
        expect(json).to eq(
          'type' => masked_value,
          'private_key' => masked_value,
          'foo' => masked_value,
          'nested' => masked_value
        )
      end
    end

    context 'with invalid JSON' do
      where(:value) { [nil, '', ' ', 'invalid json'] }

      with_them do
        it { is_expected.to eq(value) }
      end
    end
  end
end
