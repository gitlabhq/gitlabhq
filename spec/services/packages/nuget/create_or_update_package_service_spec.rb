# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CreateOrUpdatePackageService, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }

  let(:package_name) { 'MyPackage' }
  let(:package_version) { '1.0.0' }
  let(:params) do
    {
      nuspec_file_content: nuspec_content,
      build: instance_double(Ci::Build, pipeline: pipeline),
      file: fixture_file_upload('spec/fixtures/packages/nuget/package.nupkg')
    }
  end

  let(:service) { described_class.new(project, user, params) }
  let(:nuspec_content) do
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
        <metadata>
          <id>#{package_name}</id>
          <version>#{package_version}</version>
          <title>Dummy package</title>
          <authors>Test Author</authors>
          <owners>Test</owners>
          <projectUrl>http://example.com</projectUrl>
          <licenseUrl>http://example.com/license</licenseUrl>
          <iconUrl>http://example.com/icon</iconUrl>
          <tags>tag1 tag2</tags>
          <description>This is a dummy package</description>
          <dependencies>
            <group targetFramework=".NETCoreApp3.0">
              <dependency id="Dep1" version="12.0.3" exclude="Build,Analyzers" />
            </group>
          </dependencies>
        </metadata>
      </package>
    XML
  end

  describe '#execute' do
    include ExclusiveLeaseHelpers

    subject(:execute_service) { service.execute }

    context 'when creating a new package' do
      it 'creates a new package with the correct attributes and associations' do
        expect { execute_service }
          .to change { ::Packages::Nuget::Package.count }.by(1)
          .and change { ::Packages::PackageFile.count }.by(1)
          .and change { ::Packages::Tag.count }.by(2)
          .and change { ::Packages::BuildInfo.count }.by(1)
          .and change { ::Packages::Dependency.count }.by(1)
          .and change { ::Packages::DependencyLink.count }.by(1)
          .and change { ::Packages::Nuget::DependencyLinkMetadatum.count }.by(1)

        expect(execute_service).to be_success

        created_package = execute_service[:package]
        expect(created_package).to have_attributes(
          name: package_name,
          version: package_version,
          project: project,
          creator: user
        )

        package_file = created_package.package_files.first
        expect(package_file).to have_attributes(
          file_name: "#{package_name.downcase}.#{package_version.downcase}.nupkg"
        )

        expect(created_package.nuget_metadatum).to have_attributes(
          authors: 'Test Author',
          description: 'This is a dummy package',
          project_url: 'http://example.com',
          license_url: 'http://example.com/license',
          icon_url: 'http://example.com/icon'
        )

        expect(created_package.tag_names).to contain_exactly('tag1', 'tag2')

        dependency = created_package.dependency_links.first.dependency
        expect(dependency).to have_attributes(name: 'Dep1', version_pattern: '12.0.3')

        build_info = created_package.build_infos.first
        expect(build_info).to have_attributes(pipeline: pipeline)
      end
    end

    context 'when updating an existing package' do
      let!(:existing_package) { create(:nuget_package, project: project, name: package_name, version: package_version) }

      context 'when duplicates are allowed' do
        before do
          allow(Namespace::PackageSetting).to receive(:duplicates_allowed?).and_return(true)
        end

        it 'does not create a new package' do
          expect { execute_service }
            .not_to change { ::Packages::Nuget::Package.count }

          expect(execute_service).to be_success
        end

        it 'creates a new package file, tags, and build info' do
          expect { execute_service }
            .to change { ::Packages::PackageFile.count }.by(1)
            .and change { ::Packages::Tag.count }.by(2)
            .and change { ::Packages::BuildInfo.count }.by(1)
        end
      end

      context 'when duplicates are not allowed' do
        before do
          allow(::Namespace::PackageSetting).to receive(:duplicates_allowed?).and_return(false)
        end

        it 'returns an error response' do
          is_expected.to be_error.and have_attributes(
            message: 'A package with the same name and version already exists',
            reason: :conflict
          )
        end
      end
    end

    context 'when package is invalid' do
      before do
        allow_next_instance_of(::Packages::Nuget::Package) do |package|
          allow(package).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(package), 'Validation failed')
        end
      end

      it { is_expected.to be_error.and have_attributes(message: 'Validation failed', reason: :bad_request) }
    end

    context 'with exclusive lease guard' do
      let(:lease_key) { service.send(:lease_key) }

      it 'obtains a lease to create or update the package' do
        expect_to_obtain_exclusive_lease(lease_key)

        execute_service
      end

      context 'when the lease is already taken' do
        before do
          stub_exclusive_lease_taken(lease_key)
        end

        it 'returns an error response' do
          is_expected.to be_error.and have_attributes(
            message: 'Failed to obtain a lock. Please try again.',
            reason: :conflict
          )
        end
      end
    end
  end
end
