# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CreateOrUpdatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
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

  shared_examples 'valid package' do
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

  describe '#execute' do
    include ExclusiveLeaseHelpers

    subject(:execute_service) { service.execute }

    context 'when creating a new package' do
      it_behaves_like 'valid package'
    end

    context 'when updating an existing package' do
      let!(:existing_package) do
        create(:nuget_package, project: project, name: package_name, version: package_version)
      end

      context 'when duplicates are allowed' do
        before do
          allow(Namespace::PackageSetting).to receive(:duplicates_allowed?).and_return(true)
        end

        it_behaves_like 'returning a success service response'

        it 'does not create a new package' do
          expect { execute_service }
            .not_to change { ::Packages::Nuget::Package.count }
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

        it_behaves_like 'returning an error service response',
          message: 'A package with the same name and version already exists'

        it { is_expected.to have_attributes(reason: :conflict) }
      end
    end

    context 'when package is invalid' do
      before do
        allow_next_instance_of(::Packages::Nuget::Package) do |package|
          allow(package).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(package), 'Validation failed')
        end
      end

      it_behaves_like 'returning an error service response', message: 'Validation failed'

      it { is_expected.to have_attributes(reason: :bad_request) }
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

        it_behaves_like 'returning an error service response', message: 'Failed to obtain a lock. Please try again.'
        it { is_expected.to have_attributes(reason: :conflict) }
      end
    end

    context 'with unauthorized user' do
      let(:user) { create(:user) }

      it_behaves_like 'returning an error service response', message: 'Unauthorized'
      it { is_expected.to have_attributes(reason: :unauthorized) }
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :nuget, project: project)
      end

      let_it_be(:project_developer) { create(:user, developer_of: project) }
      let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:project_owner) { project.owner }
      let_it_be(:instance_admin) { create(:admin) }
      let_it_be(:deploy_token) { create(:deploy_token, :project, projects: [project], write_package_registry: true) }

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
      end

      shared_examples 'protected package' do
        it_behaves_like 'returning an error service response', message: "Package protected."
        it { is_expected.to have_attributes(reason: :package_protected) }

        it 'does not create any nuget-related package records' do
          expect { subject }
            .to not_change { Packages::Package.count }
            .and not_change { ::Packages::Nuget::Package.count }
            .and not_change { ::Packages::PackageFile.count }
            .and not_change { ::Packages::Tag.count }
            .and not_change { ::Packages::BuildInfo.count }
            .and not_change { ::Packages::Dependency.count }
            .and not_change { ::Packages::DependencyLink.count }
            .and not_change { ::Packages::Nuget::DependencyLinkMetadatum.count }
        end
      end

      shared_examples 'protected package from deploy token' do
        let(:service) { described_class.new(project, deploy_token, params) }
        let(:user) { nil }

        it_behaves_like 'protected package'
      end

      shared_examples 'valid package from deploy token' do
        let(:service) { described_class.new(project, deploy_token, params) }
        let(:user) { nil }

        it_behaves_like 'valid package'
      end

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
        ref(:package_name)               | :maintainer | ref(:project_developer)  | 'protected package'
        ref(:package_name)               | :maintainer | ref(:project_maintainer) | 'valid package'
        ref(:package_name)               | :maintainer | ref(:project_owner)      | 'valid package'
        ref(:package_name)               | :maintainer | ref(:instance_admin)     | 'valid package'
        ref(:package_name)               | :maintainer | ref(:deploy_token)       | 'protected package from deploy token'

        ref(:package_name)               | :owner      | ref(:project_maintainer) | 'protected package'
        ref(:package_name)               | :owner      | ref(:project_owner)      | 'valid package'
        ref(:package_name)               | :owner      | ref(:instance_admin)     | 'valid package'
        ref(:package_name)               | :owner      | ref(:deploy_token)       | 'protected package from deploy token'

        ref(:package_name)               | :admin      | ref(:project_owner)      | 'protected package'
        ref(:package_name)               | :admin      | ref(:instance_admin)     | 'valid package'
        ref(:package_name)               | :admin      | ref(:deploy_token)       | 'protected package from deploy token'

        lazy { "Other.#{package_name}" } | :maintainer | ref(:project_owner)      | 'valid package'
        lazy { "Other.#{package_name}" } | :admin      | ref(:project_owner)      | 'valid package'
        lazy { "Other.#{package_name}" } | :admin      | ref(:deploy_token)       | 'valid package from deploy token'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
