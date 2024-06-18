# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DebianProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project, false do
    shared_examples 'accept GET request on private project with access to package registry for everyone' do
      include_context 'Debian repository access', :private, :anonymous, :basic do
        before do
          container.project_feature.reload.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it_behaves_like 'Debian packages GET request', :success
      end
    end

    context 'with invalid parameter' do
      let(:url) { "/projects/1/packages/debian/dists/with+space/InRelease" }

      it_behaves_like 'Debian packages GET request', :bad_request, /^distribution is invalid$/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release.gpg" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^-----BEGIN PGP SIGNATURE-----/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/Release' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/Release" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^Codename: fixture-distribution\n$/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/InRelease" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :success, /^-----BEGIN PGP SIGNED MESSAGE-----/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:target_component_file) { component_file }
      let(:target_component_name) { component.name }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian packages index endpoint', /Description: This is an incomplete Packages file/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages.gz' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{component.name}/binary-#{architecture.name}/Packages.gz" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :not_found, /Format gz is not supported/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256' do
      let(:target_component_file) { component_file_older_sha256 }
      let(:target_component_name) { component.name }
      let(:target_sha256) { target_component_file.file_sha256 }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/binary-#{architecture.name}/by-hash/SHA256/#{target_sha256}" }

      it_behaves_like 'Debian packages index sha256 endpoint', /^Other SHA256$/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/source/Sources' do
      let(:target_component_file) { component_file_sources }
      let(:target_component_name) { component.name }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/source/Sources" }

      it_behaves_like 'Debian packages index endpoint', /^Description: This is an incomplete Sources file$/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256' do
      let(:target_component_file) { component_file_sources_older_sha256 }
      let(:target_component_name) { component.name }
      let(:target_sha256) { target_component_file.file_sha256 }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/source/by-hash/SHA256/#{target_sha256}" }

      it_behaves_like 'Debian packages index sha256 endpoint', /^Other SHA256$/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/Packages' do
      let(:target_component_file) { component_file_di }
      let(:target_component_name) { component.name }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/debian-installer/binary-#{architecture.name}/Packages" }

      it_behaves_like 'Debian packages index endpoint', /Description: This is an incomplete D-I Packages file/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/Packages.gz' do
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{component.name}/debian-installer/binary-#{architecture.name}/Packages.gz" }

      it_behaves_like 'Debian packages read endpoint', 'GET', :not_found, /Format gz is not supported/
    end

    describe 'GET projects/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256' do
      let(:target_component_file) { component_file_di_older_sha256 }
      let(:target_component_name) { component.name }
      let(:target_sha256) { target_component_file.file_sha256 }
      let(:url) { "/projects/#{container.id}/packages/debian/dists/#{distribution.codename}/#{target_component_name}/debian-installer/binary-#{architecture.name}/by-hash/SHA256/#{target_sha256}" }

      it_behaves_like 'Debian packages index sha256 endpoint', /^Other SHA256$/
      it_behaves_like 'accept GET request on private project with access to package registry for everyone'
    end

    describe 'GET projects/:id/packages/debian/pool/:codename/:letter/:package_name/:package_version/:file_name' do
      using RSpec::Parameterized::TableSyntax

      let(:url) { "/projects/#{container.id}/packages/debian/pool/#{package.distribution.codename}/#{letter}/#{package.name}/#{package.version}/#{file_name}" }
      let(:file_name) { params[:file_name] }

      where(:file_name, :success_body) do
        'sample_1.2.3~alpha2.tar.xz'          | /^.7zXZ/
        'sample_1.2.3~alpha2.dsc'             | /^Format: 3.0 \(native\)/
        'libsample0_1.2.3~alpha2_amd64.deb'   | /^!<arch>/
        'sample-udeb_1.2.3~alpha2_amd64.udeb' | /^!<arch>/
        'sample-ddeb_1.2.3~alpha2_amd64.ddeb' | /^!<arch>/
        'sample_1.2.3~alpha2_amd64.buildinfo' | /Build-Tainted-By/
        'sample_1.2.3~alpha2_amd64.changes'   | /urgency=medium/
      end

      with_them do
        it_behaves_like 'Debian packages read endpoint', 'GET', :success, params[:success_body]

        context 'for bumping last downloaded at' do
          include_context 'Debian repository access', :public, :developer, :basic do
            it_behaves_like 'bumping the package last downloaded at field'
          end
        end
      end

      it_behaves_like 'accept GET request on private project with access to package registry for everyone' do
        let(:file_name) { 'sample_1.2.3~alpha2.dsc' }
      end
    end

    describe 'PUT projects/:id/packages/debian/:file_name' do
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}" }

      context 'with a deb' do
        let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }

        it_behaves_like 'Debian packages write endpoint', 'upload', :created, nil
        it_behaves_like 'Debian packages endpoint catching ObjectStorage::RemoteStoreError'

        context 'with codename and component' do
          let(:extra_params) { { distribution: distribution.codename, component: 'main' } }

          it_behaves_like 'Debian packages write endpoint', 'upload', :created, nil
        end

        context 'with codename and without component' do
          let(:extra_params) { { distribution: distribution.codename } }

          include_context 'Debian repository access', :public, :developer, :basic do
            it_behaves_like 'Debian packages GET request', :bad_request, /component is missing/
          end
        end
      end

      context 'with a buildinfo' do
        let(:file_name) { 'sample_1.2.3~alpha2_amd64.buildinfo' }

        include_context 'Debian repository access', :public, :developer, :basic do
          it_behaves_like "Debian packages upload request", :created, nil
        end

        context 'with codename and component' do
          let(:extra_params) { { distribution: distribution.codename, component: 'main' } }

          include_context 'Debian repository access', :public, :developer, :basic do
            it_behaves_like "Debian packages upload request", :bad_request,
              /^file_name Only debs, udebs and ddebs can be directly added to a distribution$/
          end
        end
      end

      context 'with a changes file' do
        let(:file_name) { 'sample_1.2.3~alpha2_amd64.changes' }

        it_behaves_like 'Debian packages write endpoint', 'upload', :created, nil
      end
    end

    describe 'PUT projects/:id/packages/debian/:file_name/authorize' do
      let(:file_name) { 'libsample0_1.2.3~alpha2_amd64.deb' }
      let(:method) { :put }
      let(:url) { "/projects/#{container.id}/packages/debian/#{file_name}/authorize" }

      it_behaves_like 'Debian packages write endpoint', 'upload authorize', :created, nil
    end
  end
end
