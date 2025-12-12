# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ExtractionWorker, type: :worker, feature_category: :package_registry do
  describe '#perform' do
    let!(:package) { create(:nuget_package) }
    let(:package_file) { package.package_files.first }
    let(:package_file_id) { package_file.id }

    let_it_be(:package_name) { 'DummyProject.DummyPackage' }
    let_it_be(:package_version) { '1.0.0' }

    subject { described_class.new.perform(package_file_id) }

    shared_examples 'handling error' do |error_message:,
      error_class: ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError|
      it 'updates package status to error', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(error_class),
          {
            package_file_id: package_file.id,
            project_id: package.project_id
          }
        )

        subject

        expect(package.reload).to be_error
        expect(package.status_message).to match(error_message)
      end
    end

    shared_examples 'updates package and package file' do
      it 'updates package and package file' do
        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
      end
    end

    context 'with valid package file' do
      it_behaves_like 'updates package and package file'

      context 'with exisiting package' do
        let!(:existing_package) { create(:nuget_package, project: package.project, name: package_name, version: package_version) }

        it 'reuses existing package and updates package file' do
          expect { subject }
            .to change { Packages::Package.count }.by(-1)
            .and change { existing_package.reload.package_files.count }.by(1)
            .and not_change { Packages::PackageFile.count }
        end
      end
    end

    context 'with invalid package file id' do
      let(:package_file_id) { 5555 }

      it "doesn't update package and package file" do
        expect { subject }
          .to not_change { package.reload.name }
          .and not_change { package.version }
          .and not_change { package_file.reload.file_name }
      end
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let(:package_protection_rule) do
        create(:package_protection_rule, package_type: :nuget, project: package.project)
      end

      let(:package_name_pattern) { 'DummyProject.*' }

      let(:project_developer) { create(:user, developer_of: package.project) }
      let(:project_maintainer) { create(:user, maintainer_of: package.project) }
      let(:project_owner) { package.project.owner }
      let(:instance_admin) { create(:admin) }

      let(:project_deploy_token) { create(:deploy_token, :project, projects: [package.project], write_package_registry: true) }

      subject { described_class.new.perform(package_file_id, params) }

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
        package.update!(creator: package_creator)
      end

      shared_examples 'protected package' do
        it_behaves_like 'handling error',
          error_class: ::Packages::Nuget::UpdatePackageFromMetadataService::ProtectedPackageError,
          error_message: "Package 'DummyProject.DummyPackage' with version '1.0.0' is protected"
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :package_creator, :params, :shared_examples_name) do
        ref(:package_name)               | :maintainer | ref(:project_developer)  | { user_id: ref(:project_developer) }            | 'protected package'
        ref(:package_name)               | :maintainer | ref(:project_developer)  | {}                                              | 'protected package'
        ref(:package_name)               | :maintainer | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'updates package and package file'
        ref(:package_name)               | :maintainer | ref(:project_maintainer) | {}                                              | 'updates package and package file'
        ref(:package_name)               | :maintainer | nil                      | {}                                              | 'protected package'
        ref(:package_name)               | :maintainer | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        ref(:package_name)               | :owner      | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'protected package'
        ref(:package_name)               | :owner      | ref(:project_maintainer) | {}                                              | 'protected package'
        ref(:package_name)               | :owner      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'updates package and package file'
        ref(:package_name)               | :owner      | nil                      | {}                                              | 'protected package'
        ref(:package_name)               | :owner      | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        ref(:package_name)               | :admin      | ref(:project_maintainer) | { user_id: ref(:project_maintainer) }           | 'protected package'
        ref(:package_name)               | :admin      | ref(:project_maintainer) | {}                                              | 'protected package'
        ref(:package_name)               | :admin      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'protected package'
        ref(:package_name)               | :admin      | ref(:instance_admin)     | { user_id: ref(:instance_admin) }               | 'updates package and package file'
        ref(:package_name)               | :admin      | ref(:instance_admin)     | {}                                              | 'updates package and package file'
        ref(:package_name)               | :admin      | nil                      | {}                                              | 'protected package'
        ref(:package_name)               | :admin      | nil                      | { deploy_token_id: ref(:project_deploy_token) } | 'protected package'

        lazy { "Other.#{package_name}" } | :admin      | ref(:project_owner)      | { user_id: ref(:project_owner) }                | 'updates package and package file'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | {}                                              | 'updates package and package file'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | {}                                              | 'updates package and package file'
        lazy { "Other.#{package_name}" } | :admin      | nil                      | nil                                             | 'updates package and package file'
      end

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with controlled errors' do
      context 'with package file not containing a nuspec file' do
        before do
          allow_any_instance_of(Zip::File).to receive(:glob).and_return([])
        end

        it_behaves_like 'handling error',
          error_class: ::Packages::Nuget::ExtractMetadataFileService::ExtractionError,
          error_message: 'nuspec file not found'
      end

      context 'with invalid metadata' do
        shared_context 'with a blank attribute' do
          before do
            allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
              allow(service).to receive(attribute).and_return('')
            end
          end
        end

        context 'with a blank package name' do
          include_context 'with a blank attribute' do
            let(:attribute) { :package_name }

            it_behaves_like 'handling error', error_message: /not found in metadata/
          end
        end

        context 'with package with an invalid package name' do
          invalid_names = [
            'My/package',
            '../../../my_package',
            '%2e%2e%2fmy_package'
          ]

          invalid_names.each do |invalid_name|
            context "with #{invalid_name}" do
              before do
                allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
                  allow(service).to receive(:package_name).and_return(invalid_name)
                end
              end

              it_behaves_like 'handling error', error_message: 'Validation failed: Name is invalid'
            end
          end
        end

        context 'with package with a blank package version' do
          include_context 'with a blank attribute' do
            let(:attribute) { :package_version }

            it_behaves_like 'handling error', error_message: /not found in metadata/
          end
        end

        context 'with package with an invalid package version' do
          invalid_versions = [
            '555',
            '1./2.3',
            '../../../../../1.2.3',
            '%2e%2e%2f1.2.3'
          ]

          invalid_versions.each do |invalid_version|
            context "with #{invalid_version}" do
              before do
                allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
                  allow(service).to receive(:package_version).and_return(invalid_version)
                end
              end

              it_behaves_like 'handling error', error_message: 'Validation failed: Version is invalid'
            end
          end
        end
      end

      context 'handling a Zip::Error exception' do
        before do
          allow_any_instance_of(::Packages::UpdatePackageFileService).to receive(:execute).and_raise(::Zip::Error)
        end

        it_behaves_like 'handling error',
          error_class: ::Packages::Nuget::UpdatePackageFromMetadataService::ZipError,
          error_message: 'Could not open the .nupkg file'
      end
    end

    context 'with uncontrolled errors' do
      before do
        allow_any_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService).to receive(:execute).and_raise(StandardError.new('Boom'))
      end

      it_behaves_like 'handling error', error_class: StandardError, error_message: 'Unexpected error: StandardError'
    end

    context 'with the error when fetching a package file' do
      let(:exception) { ActiveRecord::QueryCanceled.new('ERROR: canceling statement due to statement timeout') }

      before do
        allow(::Packages::PackageFile).to receive(:find_by_id).with(package_file_id).and_raise(exception)
      end

      it 'raises the error' do
        expect { subject }.to raise_error(exception.class)
      end
    end
  end
end
