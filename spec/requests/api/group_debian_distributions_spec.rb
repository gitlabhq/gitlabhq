# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::GroupDebianDistributions, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group, false do
    describe 'POST groups/:id/-/debian_distributions' do
      let(:method) { :post }
      let(:url) { "/groups/#{container.id}/-/debian_distributions" }
      let(:api_params) { { codename: 'my-codename' } }

      it_behaves_like 'Debian distributions write endpoint', 'POST', :created, /^{.*"codename":"my-codename",.*"components":\["main"\],.*"architectures":\["all","amd64"\]/

      it_behaves_like 'authorizing granular token permissions', :create_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { post api("/groups/#{boundary_object.id}/-/debian_distributions"), headers: headers, params: api_params }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET groups/:id/-/debian_distributions' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^\[{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/groups/#{boundary_object.id}/-/debian_distributions"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET groups/:id/-/debian_distributions/:codename' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/groups/#{private_container.id}/-/debian_distributions/#{distribution.codename}"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET groups/:id/-/debian_distributions/:codename/key.asc' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}/key.asc" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^-----BEGIN PGP PUBLIC KEY BLOCK-----/

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/groups/#{boundary_object.id}/-/debian_distributions/#{distribution.codename}/key.asc"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'PUT groups/:id/-/debian_distributions/:codename' do
      let(:method) { :put }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }
      let(:api_params) { { suite: 'my-suite' } }

      it_behaves_like 'Debian distributions write endpoint', 'PUT', :success, /^{.*"codename":"existing-codename",.*"suite":"my-suite",/

      it_behaves_like 'authorizing granular token permissions', :update_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { workhorse_headers.merge({ 'Private-Token' => pat.token }) }
        let(:request) do
          workhorse_finalize(
            api("/groups/#{boundary_object.id}/-/debian_distributions/#{distribution.codename}"),
            method: :put,
            file_key: :file,
            params: api_params,
            headers: headers,
            send_rewritten_field: true
          )
        end

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'DELETE groups/:id/-/debian_distributions/:codename' do
      let(:method) { :delete }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions maintainer write endpoint', 'DELETE', :success, /^{"message":"202 Accepted"}$/

      it_behaves_like 'authorizing granular token permissions', :delete_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { delete api("/groups/#{boundary_object.id}/-/debian_distributions/#{distribution.codename}"), headers: headers }
        before do
          private_container.add_maintainer(user)
        end
      end
    end
  end
end
