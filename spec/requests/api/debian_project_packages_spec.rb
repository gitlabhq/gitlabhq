# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianProjectPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, true do
    describe 'GET projects/:id/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution}/Release.gpg" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution}/Release" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO Release'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution}/InRelease" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution}/#{component}/binary-#{architecture}/Packages" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO Packages'
    end

    describe 'GET projects/:id/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/projects/#{container.id}/packages/debian/pool/#{component}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture}.deb" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, 'TODO File'
    end

    describe 'PUT projects/:id/packages/debian/:file_name' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}" }

      it_behaves_like 'Debian repository write endpoint', 'upload request', :created
    end

    describe 'PUT projects/:id/packages/debian/:file_name/authorize' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}/authorize" }

      it_behaves_like 'Debian repository write endpoint', 'upload authorize request', :created
    end
  end
end
