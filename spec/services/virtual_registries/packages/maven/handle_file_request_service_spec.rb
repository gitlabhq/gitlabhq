# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::HandleFileRequestService, :aggregate_failures, feature_category: :virtual_registry do
  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry, :with_upstream) }
  let_it_be(:project) { create(:project, namespace: registry.group) }
  let_it_be(:user) { create(:user, owner_of: project) }

  let(:upstream) { registry.upstream }
  let(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }
  let(:upstream_resource_url) { upstream.url_for(path) }
  let(:service) { described_class.new(registry: registry, current_user: user, params: { path: path }) }

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'returning a service response error response with' do |message:, reason:|
      it 'returns an error' do
        expect(execute).to be_a(ServiceResponse)
        expect(execute).to be_error
        expect(execute.message).to eq(message)
        expect(execute.reason).to eq(reason)
      end
    end

    shared_examples 'returning a service response success response' do
      before do
        stub_external_registry_request
      end

      it 'returns a success service response' do
        expect(execute).to be_success
        expect(execute.payload).to eq(
          action: :workhorse_send_url,
          action_params: { url: upstream_resource_url, headers: upstream.headers }
        )
      end
    end

    context 'with a User' do
      it_behaves_like 'returning a service response success response'

      context 'with upstream returning an error' do
        before do
          stub_external_registry_request(status: 404)
        end

        it_behaves_like 'returning a service response error response with', message: 'File not found on any upstream',
          reason: :file_not_found_on_upstreams
      end

      context 'with upstream head raising an error' do
        before do
          stub_external_registry_request(raise_error: true)
        end

        it_behaves_like 'returning a service response error response with', message: 'Upstream not available',
          reason: :upstream_not_available
      end
    end

    context 'with a DeployToken' do
      let_it_be(:user) { create(:deploy_token, :group, groups: [registry.group], read_virtual_registry: true) }

      it_behaves_like 'returning a service response success response'
    end

    context 'with no path' do
      let(:path) { nil }

      it_behaves_like 'returning a service response error response with', message: 'Path not present',
        reason: :path_not_present
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'returning a service response error response with', message: 'Unauthorized', reason: :unauthorized
    end

    context 'with registry with no upstreams' do
      before do
        registry.upstream = nil
      end

      it_behaves_like 'returning a service response error response with', message: 'No upstreams set',
        reason: :no_upstreams
    end

    def stub_external_registry_request(status: 200, raise_error: false)
      request = stub_request(:head, upstream_resource_url)
        .with(headers: upstream.headers)

      if raise_error
        request.to_raise(Gitlab::HTTP::BlockedUrlError)
      else
        request.to_return(status: status, body: '')
      end
    end
  end
end
