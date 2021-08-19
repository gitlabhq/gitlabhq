# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::GroupDebianDistributions do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group, false do
    describe 'POST groups/:id/-/debian_distributions' do
      let(:method) { :post }
      let(:url) { "/groups/#{container.id}/-/debian_distributions" }
      let(:api_params) { { 'codename': 'my-codename' } }

      it_behaves_like 'Debian repository write endpoint', 'POST distribution request', :created, /^{.*"codename":"my-codename",.*"components":\["main"\],.*"architectures":\["all","amd64"\]/, authenticate_non_public: false
    end

    describe 'GET groups/:id/-/debian_distributions' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^\[{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/, authenticate_non_public: false
    end

    describe 'GET groups/:id/-/debian_distributions/:codename' do
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^{.*"codename":"existing-codename",.*"components":\["existing-component"\],.*"architectures":\["all","existing-arch"\]/, authenticate_non_public: false
    end

    describe 'PUT groups/:id/-/debian_distributions/:codename' do
      let(:method) { :put }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }
      let(:api_params) { { suite: 'my-suite' } }

      it_behaves_like 'Debian repository write endpoint', 'PUT distribution request', :success, /^{.*"codename":"existing-codename",.*"suite":"my-suite",/, authenticate_non_public: false
    end

    describe 'DELETE groups/:id/-/debian_distributions/:codename' do
      let(:method) { :delete }
      let(:url) { "/groups/#{container.id}/-/debian_distributions/#{distribution.codename}" }

      it_behaves_like 'Debian repository maintainer write endpoint', 'DELETE distribution request', :success, /^{"message":"202 Accepted"}$/, authenticate_non_public: false
    end
  end
end
