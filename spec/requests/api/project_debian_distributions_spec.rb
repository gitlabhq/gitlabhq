# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::ProjectDebianDistributions, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, false do
    shared_examples 'accept GET request on private project with access to package registry for everyone' do
      include_context 'Debian repository access', :private, :anonymous, :basic do
        before do
          container.project_feature.reload.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it_behaves_like 'Debian distributions GET request', :success
      end
    end

    describe 'POST projects/:id/debian_distributions' do
      let(:method) { :post }
      let(:url) { "/projects/#{container.id}/debian_distributions" }
      let(:api_params) { { codename: 'my-codename' } }

      it_behaves_like 'Debian distributions write endpoint', 'POST', :created, /^{.*"codename":"my-codename",.*"components":\["main"\],.*"architectures":\["all","amd64"\]/

      context 'with invalid parameters' do
        let(:api_params) { { codename: distribution.codename } }

        it_behaves_like 'Debian distributions write endpoint', 'GET', :bad_request, /^{"message":{"codename":\["has already been taken"\]}}$/
      end

      context 'with access to package registry for everyone' do
        include_context 'Debian repository access', :private, :anonymous, :basic do
          before do
            container.project_feature.reload.update!(package_registry_access_level: ProjectFeature::PUBLIC)
          end

          it_behaves_like 'Debian distributions POST request', :not_found
        end
      end

      it_behaves_like 'authorizing granular token permissions', :create_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { post api("/projects/#{boundary_object.id}/debian_distributions"), headers: headers, params: api_params }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET projects/:id/debian_distributions' do
      let(:url) { "/projects/#{container.id}/debian_distributions" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^\[{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/projects/#{boundary_object.id}/debian_distributions"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET projects/:id/debian_distributions/:codename' do
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/projects/#{private_container.id}/debian_distributions/#{distribution.codename}"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'GET projects/:id/debian_distributions/:codename/key.asc' do
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}/key.asc" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^-----BEGIN PGP PUBLIC KEY BLOCK-----/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'

      it_behaves_like 'authorizing granular token permissions', :read_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { get api("/projects/#{boundary_object.id}/debian_distributions/#{distribution.codename}/key.asc"), headers: headers }

        before do
          private_container.add_developer(user)
        end
      end
    end

    describe 'PUT projects/:id/debian_distributions/:codename' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }
      let(:api_params) { { suite: 'my-suite' } }

      it_behaves_like 'Debian distributions write endpoint', 'PUT', :success, /^{.*"codename":"existing-codename",.*"suite":"my-suite",/

      context 'with invalid parameters' do
        let(:api_params) { { suite: distribution.codename } }

        it_behaves_like 'Debian distributions write endpoint', 'GET', :bad_request, /^{"message":{"suite":\["has already been taken as Codename"\]}}$/
      end

      it_behaves_like 'authorizing granular token permissions', :update_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { workhorse_headers.merge({ 'Private-Token' => pat.token }) }
        let(:request) do
          workhorse_finalize(
            api("/projects/#{boundary_object.id}/debian_distributions/#{distribution.codename}"),
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

    describe 'DELETE projects/:id/debian_distributions/:codename' do
      let(:method) { :delete }
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions maintainer write endpoint', 'DELETE', :success, /^{"message":"202 Accepted"}$/

      context 'when destroy fails' do
        before do
          allow_next_found_instance_of(::Packages::Debian::ProjectDistribution) do |distribution|
            expect(distribution).to receive(:destroy).and_return(false)
          end
        end

        it_behaves_like 'Debian distributions maintainer write endpoint', 'GET', :bad_request, /^{"message":"Failed to delete distribution"}$/
      end

      it_behaves_like 'authorizing granular token permissions', :delete_debian_distribution do
        let(:boundary_object) { private_container }
        let(:headers) { { 'Private-Token' => pat.token } }
        let(:request) { delete api("/projects/#{boundary_object.id}/debian_distributions/#{distribution.codename}"), headers: headers }

        before do
          private_container.add_maintainer(user)
        end
      end
    end
  end
end
