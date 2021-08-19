# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianProjectPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, true do
    context 'with invalid parameter' do
      let(:url) { "/projects/1/packages/debian/dists/with+space/InRelease" }

      it_behaves_like 'Debian repository GET request', :bad_request, /^distribution is invalid$/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release.gpg" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^-----BEGIN PGP SIGNATURE-----/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^Codename: fixture-distribution\n$/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/InRelease" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /^-----BEGIN PGP SIGNED MESSAGE-----/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{component.name}/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian repository read endpoint', 'GET request', :success, /Description: This is an incomplete Packages file/
    end

    describe 'GET projects/:id/packages/debian/pool/:codename/:letter/:package_name/:package_version/:file_name' do
      let(:url) { "/projects/#{container.id}/packages/debian/pool/#{package.debian_distribution.codename}/#{letter}/#{package.name}/#{package.version}/#{file_name}" }

      using RSpec::Parameterized::TableSyntax

      where(:file_name, :success_body) do
        'sample_1.2.3~alpha2.tar.xz'          | /^.7zXZ/
        'sample_1.2.3~alpha2.dsc'             | /^Format: 3.0 \(native\)/
        'libsample0_1.2.3~alpha2_amd64.deb'   | /^!<arch>/
        'sample-udeb_1.2.3~alpha2_amd64.udeb' | /^!<arch>/
        'sample_1.2.3~alpha2_amd64.buildinfo' | /Build-Tainted-By/
        'sample_1.2.3~alpha2_amd64.changes'   | /urgency=medium/
      end

      with_them do
        include_context 'with file_name', params[:file_name]

        it_behaves_like 'Debian repository read endpoint', 'GET request', :success, params[:success_body]
      end
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
