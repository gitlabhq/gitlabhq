# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::ProjectDebianDistributions do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, true do
    describe 'POST projects/:id/debian_distributions' do
      let(:method) { :post }
      let(:url) { "/projects/#{container.id}/debian_distributions" }
      let(:api_params) { { 'codename': 'my-codename' } }

      it_behaves_like 'Debian repository write endpoint', 'POST distribution request', :created, /^{.*"codename":"my-codename",.*"components":\["main"\],.*"architectures":\["all","amd64"\]/, authenticate_non_public: false

      context 'with invalid parameters' do
        let(:api_params) { { codename: distribution.codename } }

        it_behaves_like 'Debian repository write endpoint', 'GET request', :bad_request, /^{"message":{"codename":\["has already been taken"\]}}$/, authenticate_non_public: false
      end
    end

    describe 'GET projects/:id/debian_distributions' do
      let(:url) { "/projects/#{container.id}/debian_distributions" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^\[{.*"codename":"existing-codename\",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/, authenticate_non_public: false
    end

    describe 'GET projects/:id/debian_distributions/:codename' do
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^{.*"codename":"existing-codename\",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/, authenticate_non_public: false
    end

    describe 'PUT projects/:id/debian_distributions/:codename' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }
      let(:api_params) { { suite: 'my-suite' } }

      it_behaves_like 'Debian repository write endpoint', 'PUT distribution request', :success, /^{.*"codename":"existing-codename",.*"suite":"my-suite",/, authenticate_non_public: false

      context 'with invalid parameters' do
        let(:api_params) { { suite: distribution.codename } }

        it_behaves_like 'Debian repository write endpoint', 'GET request', :bad_request, /^{"message":{"suite":\["has already been taken as Codename"\]}}$/, authenticate_non_public: false
      end
    end

    describe 'DELETE projects/:id/debian_distributions/:codename' do
      let(:method) { :delete }
      let(:url) { "/projects/#{container.id}/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian repository maintainer write endpoint', 'DELETE distribution request', :success, /^{\"message\":\"202 Accepted\"}$/, authenticate_non_public: false

      context 'when destroy fails' do
        before do
          allow_next_found_instance_of(::Packages::Debian::ProjectDistribution) do |distribution|
            expect(distribution).to receive(:destroy).and_return(false)
          end
        end

        it_behaves_like 'Debian repository maintainer write endpoint', 'GET request', :bad_request, /^{"message":"Failed to delete distribution"}$/, authenticate_non_public: false
      end
    end
  end
end
