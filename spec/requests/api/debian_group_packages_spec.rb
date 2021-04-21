# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianGroupPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :group do
    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/groups/#{group.id}/-/packages/debian/dists/#{distribution}/Release.gpg" }

      it_behaves_like 'Debian group repository GET endpoint', :not_found, nil
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/Release' do
      let(:url) { "/groups/#{group.id}/-/packages/debian/dists/#{distribution}/Release" }

      it_behaves_like 'Debian group repository GET endpoint', :success, 'TODO Release'
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/groups/#{group.id}/-/packages/debian/dists/#{distribution}/InRelease" }

      it_behaves_like 'Debian group repository GET endpoint', :not_found, nil
    end

    describe 'GET groups/:id/-/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/groups/#{group.id}/-/packages/debian/dists/#{distribution}/#{component}/binary-#{architecture}/Packages" }

      it_behaves_like 'Debian group repository GET endpoint', :success, 'TODO Packages'
    end

    describe 'GET groups/:id/-/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/groups/#{group.id}/-/packages/debian/pool/#{component}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture}.deb" }

      it_behaves_like 'Debian group repository GET endpoint', :success, 'TODO File'
    end
  end
end
