# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:query) { graphql_query_for('metadata', {}, all_graphql_fields_for('Metadata')) }

  context 'logged in' do
    let(:expected_data) do
      {
        'metadata' => {
          'version' => Gitlab::VERSION,
          'revision' => Gitlab.revision,
          'kas' => {
            'enabled' => Gitlab::Kas.enabled?,
            'version' => expected_kas_version,
            'externalUrl' => expected_kas_external_url,
            'externalK8sProxyUrl' => expected_kas_external_k8s_proxy_url
          },
          'enterprise' => Gitlab.ee?
        }
      }
    end

    context 'kas is enabled' do
      let(:kas_version_info) { Gitlab::VersionInfo.new(1, 2, 3) }
      let(:expected_kas_version) { kas_version_info.to_s }
      let(:expected_kas_external_url) { Gitlab::Kas.external_url }
      let(:expected_kas_external_k8s_proxy_url) { Gitlab::Kas.tunnel_url }

      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
      end

      context 'when kas server info fetched successfully' do
        before do
          allow_next_instance_of(Gitlab::Kas::ServerInfo) do |server_info|
            allow(server_info).to receive(:version_info).and_return(kas_version_info)
          end
          post_graphql(query, current_user: current_user)
        end

        it 'returns version, revision, kas_enabled, kas_version, kas_external_url' do
          expect(graphql_errors).to be_nil
          expect(graphql_data).to eq(expected_data)
        end
      end

      context 'when failed to fetch kas server info' do
        let(:expected_kas_version) { nil }

        before do
          allow_next_instance_of(Gitlab::Kas::ServerInfo) do |server_info|
            # Upon RPC failure, Gitlab::Kas::ServerInfo#version_info could return nil after reporting the error.
            allow(server_info).to receive(:version_info).and_return nil
          end
          post_graphql(query, current_user: current_user)
        end

        it 'returns nil as kas version' do
          expect(graphql_errors).to be_nil
          expect(graphql_data).to eq(expected_data)
        end
      end
    end

    context 'kas is disabled' do
      let(:expected_kas_version) { nil }
      let(:expected_kas_external_url) { nil }
      let(:expected_kas_external_k8s_proxy_url) { nil }

      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(false)
        post_graphql(query, current_user: current_user)
      end

      it 'returns version and revision' do
        expect(graphql_errors).to be_nil
        expect(graphql_data).to eq(expected_data)
      end
    end
  end

  context 'logged in and featureFlags field' do
    feature_flags_field = <<~NODE
      featureFlags(names: ["foo", "bar", "lorem", "ipsum", "dolar"]) {
        name
        enabled
      }
    NODE

    let(:query) { graphql_query_for('metadata', {}, feature_flags_field) }

    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(false)
      stub_feature_flag_definition('foo')
      stub_feature_flag_definition('ipsum')
      stub_feature_flag_definition('dolar')

      stub_feature_flags(foo: true)
      stub_feature_flags(ipsum: current_user)
      stub_feature_flags(dolar: false)
    end

    it 'returns feature flags', :aggregate_failures do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_nil
      expect(graphql_data).to eq({
        'metadata' => {
          'featureFlags' => [
            { 'name' => 'foo', 'enabled' => true },
            { 'name' => 'ipsum', 'enabled' => true },
            { 'name' => 'dolar', 'enabled' => false }
          ]
        }
      })
    end

    it 'avoids N+1 queries' do
      first_user = create(:user)
      second_user = create(:user)

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user)
      end

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)
    end
  end

  context 'anonymous user' do
    it 'returns nothing' do
      post_graphql(query, current_user: nil)

      expect(graphql_errors).to be_nil
      expect(graphql_data).to eq('metadata' => nil)
    end

    it 'avoids unnecessary kas query' do
      post_graphql(query, current_user: nil)

      expect(Gitlab::Kas).not_to receive(:enabled?)
    end
  end
end
