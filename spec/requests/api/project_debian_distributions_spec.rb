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
    end

    describe 'GET projects/:id/debian_distributions' do
      let(:url) { "/projects/#{container.id}/debian_distributions" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^\[{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/debian_distributions/:codename' do
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/debian_distributions/:codename/key.asc' do
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}/key.asc" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^-----BEGIN PGP PUBLIC KEY BLOCK-----/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
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
    end
  end
end
