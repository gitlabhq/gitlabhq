# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianGroupPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group, false do
    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution}/Release.gpg" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution}/Release" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO Release'
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution}/InRelease" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution}/#{component}/binary-#{architecture}/Packages" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO Packages'
    end

    describe 'GET groups/:id/-/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/pool/#{component}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture}.deb" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO File'
    end
  end
end
