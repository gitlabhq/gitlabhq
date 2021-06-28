# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianProjectPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, true do
    describe 'GET projects/:id/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release.gpg" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :not_found
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/InRelease" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{component.name}/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /Description: This is an incomplete Packages file/
    end

    describe 'GET projects/:id/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/projects/#{container.id}/packages/debian/pool/#{component.name}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture.name}.deb" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^TODO File$/
    end

    describe 'PUT projects/:id/packages/debian/:file_name' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}" }
      let(:snowplow_gitlab_standard_context) { { project: container, user: user, namespace: container.namespace } }

      context 'with a deb' do
        let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }

        it_behaves_like 'Debian repository write endpoint', 'upload request', :created
      end

      context 'with a changes file' do
        let(:file_name) { 'sample_1.2.3~alpha2_amd64.changes' }

        it_behaves_like 'Debian repository write endpoint', 'upload request', :created
      end
    end

    describe 'PUT projects/:id/packages/debian/:file_name/authorize' do
      let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}/authorize" }

      it_behaves_like 'Debian repository write endpoint', 'upload authorize request', :created
    end
  end
end
