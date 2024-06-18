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
    end

    describe 'GET groups/:id/-/debian_distributions' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^\[{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
    end

    describe 'GET groups/:id/-/debian_distributions/:codename' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/
    end

    describe 'GET groups/:id/-/debian_distributions/:codename/key.asc' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}/key.asc" }

      it_behaves_like 'Debian distributions read endpoint', 'GET', :success, /^-----BEGIN PGP PUBLIC KEY BLOCK-----/
    end

    describe 'PUT groups/:id/-/debian_distributions/:codename' do
      let(:method) { :put }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }
      let(:api_params) { { suite: 'my-suite' } }

      it_behaves_like 'Debian distributions write endpoint', 'PUT', :success, /^{.*"codename":"existing-codename",.*"suite":"my-suite",/
    end

    describe 'DELETE groups/:id/-/debian_distributions/:codename' do
      let(:method) { :delete }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian distributions maintainer write endpoint', 'DELETE', :success, /^{"message":"202 Accepted"}$/
    end
  end
end
