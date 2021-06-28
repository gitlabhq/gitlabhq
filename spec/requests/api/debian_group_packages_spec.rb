# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianGroupPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group, false do
    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/Release.gpg" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/Release" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/InRelease" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/dists/#{distribution.codename}/#{component.name}/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /Description: This is an incomplete Packages file/
    end

    describe 'GET groups/:id/-/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/groups/#{container.id}/-/packages/debian/pool/#{component.name}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture.name}.deb" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^TODO File$/
    end
  end
end
