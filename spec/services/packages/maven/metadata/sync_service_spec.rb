# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::Metadata::SyncService do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:versionless_package_for_versions) { create(:maven_package, name: 'test', version: nil, project: project) }
  let_it_be_with_reload(:metadata_file_for_versions) { create(:package_file, :xml, package: versionless_package_for_versions) }

  let(:service) { described_class.new(container: project, current_user: user, params: { package_name: versionless_package_for_versions.name }) }

  describe '#execute' do
    let(:create_versions_xml_service_double) { double(::Packages::Maven::Metadata::CreateVersionsXmlService, execute: create_versions_xml_service_response) }
    let(:append_package_file_service_double) { double(::Packages::Maven::Metadata::AppendPackageFileService, execute: append_package_file_service_response) }

    let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_versions: false, metadata_content: 'test' }) }
    let(:append_package_file_service_response) { ServiceResponse.success(message: 'New metadata package files created') }

    subject { service.execute }

    before do
      allow(::Packages::Maven::Metadata::CreateVersionsXmlService)
        .to receive(:new).with(metadata_content: an_instance_of(ObjectStorage::Concern::OpenFile), package: versionless_package_for_versions).and_return(create_versions_xml_service_double)
      allow(::Packages::Maven::Metadata::AppendPackageFileService)
        .to receive(:new).with(metadata_content: an_instance_of(String), package: versionless_package_for_versions).and_return(append_package_file_service_double)
    end

    context 'permissions' do
      where(:role, :expected_result) do
        :anonymous  | :rejected
        :developer  | :rejected
        :maintainer | :accepted
      end

      with_them do
        if params[:role] == :anonymous
          let_it_be(:user) { nil }
        end

        before do
          project.send("add_#{role}", user) unless role == :anonymous
        end

        if params[:expected_result] == :rejected
          it_behaves_like 'returning an error service response', message: 'Not allowed'
        else
          it_behaves_like 'returning a success service response', message: 'New metadata package files created'
        end
      end
    end

    context 'with a maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'with a jar package' do
        before do
          expect(::Packages::Maven::Metadata::CreatePluginsXmlService).not_to receive(:new)
        end

        context 'with no changes' do
          let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: false }) }

          before do
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
          end

          it_behaves_like 'returning a success service response', message: 'No changes for versions xml'
        end

        context 'with changes' do
          let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_versions: false, metadata_content: 'new metadata' }) }

          it_behaves_like 'returning a success service response', message: 'New metadata package files created'

          context 'with empty versions' do
            let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_versions: true }) }

            before do
              expect(service.send(:versionless_package_for_versions)).to receive(:destroy!)
              expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            end

            it_behaves_like 'returning a success service response', message: 'Versionless package for versions destroyed'
          end
        end

        context 'with a too big maven metadata file for versions' do
          before do
            metadata_file_for_versions.update!(size: 100.megabytes)
          end

          it_behaves_like 'returning an error service response', message: 'Metadata file for versions is too big'
        end

        context 'an error from the create versions xml service' do
          let(:create_versions_xml_service_response) { ServiceResponse.error(message: 'metadata_content is invalid') }

          before do
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
          end

          it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
        end

        context 'an error from the append package file service' do
          let(:append_package_file_service_response) { ServiceResponse.error(message: 'metadata content is not set') }

          it_behaves_like 'returning an error service response', message: 'metadata content is not set'
        end

        context 'without a package name' do
          let(:service) { described_class.new(container: project, current_user: user, params: { package_name: nil }) }

          before do
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
          end

          it_behaves_like 'returning an error service response', message: 'Blank package name'
        end

        context 'without a versionless package for version' do
          before do
            versionless_package_for_versions.update!(version: '2.2.2')
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
          end

          it_behaves_like 'returning a success service response', message: 'Non existing versionless package(s). Nothing to do.'
        end

        context 'without a metadata package file for versions' do
          before do
            versionless_package_for_versions.package_files.update_all(file_name: 'test.txt')
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
          end

          it_behaves_like 'returning a success service response', message: 'Non existing versionless package(s). Nothing to do.'
        end

        context 'without a project' do
          let(:service) { described_class.new(container: nil, current_user: user, params: { package_name: versionless_package_for_versions.name }) }

          before do
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
          end

          it_behaves_like 'returning an error service response', message: 'Not allowed'
        end
      end

      context 'with a maven plugin package' do
        let_it_be(:versionless_package_name_for_plugins) { versionless_package_for_versions.maven_metadatum.app_group.tr('.', '/') }
        let_it_be_with_reload(:versionless_package_for_plugins) { create(:maven_package, name: versionless_package_name_for_plugins, version: nil, project: project) }
        let_it_be_with_reload(:metadata_file_for_plugins) { create(:package_file, :xml, package: versionless_package_for_plugins) }

        let(:create_plugins_xml_service_double) { double(::Packages::Maven::Metadata::CreatePluginsXmlService, execute: create_plugins_xml_service_response) }
        let(:create_plugins_xml_service_response) { ServiceResponse.success(payload: { changes_exist: false }) }

        before do
          allow(::Packages::Maven::Metadata::CreatePluginsXmlService)
            .to receive(:new).with(metadata_content: an_instance_of(ObjectStorage::Concern::OpenFile), package: versionless_package_for_plugins).and_return(create_plugins_xml_service_double)
          allow(::Packages::Maven::Metadata::AppendPackageFileService)
            .to receive(:new).with(metadata_content: an_instance_of(String), package: versionless_package_for_plugins).and_return(append_package_file_service_double)
        end

        context 'with no changes' do
          let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: false }) }

          before do
            expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
          end

          it_behaves_like 'returning a success service response', message: 'No changes for versions xml'
        end

        context 'with changes in the versions xml' do
          let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_versions: false, metadata_content: 'new metadata' }) }

          it_behaves_like 'returning a success service response', message: 'New metadata package files created'

          context 'with changes in the plugin xml' do
            let(:create_plugins_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_plugins: false, metadata_content: 'new metadata' }) }

            it_behaves_like 'returning a success service response', message: 'New metadata package files created'
          end

          context 'with empty versions' do
            let(:create_versions_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_versions: true }) }
            let(:create_plugins_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_plugins: true }) }

            before do
              expect(service.send(:versionless_package_for_versions)).to receive(:destroy!)
              expect(service.send(:metadata_package_file_for_plugins).package).to receive(:destroy!)
              expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            end

            it_behaves_like 'returning a success service response', message: 'Versionless package for versions destroyed'
          end

          context 'with a too big maven metadata file for plugins' do
            before do
              metadata_file_for_plugins.update!(size: 100.megabytes)
            end

            it_behaves_like 'returning an error service response', message: 'Metadata file for plugins is too big'
          end

          context 'an error from the create versions xml service' do
            let(:create_plugins_xml_service_response) { ServiceResponse.error(message: 'metadata_content is invalid') }

            before do
              expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
              expect(::Packages::Maven::Metadata::AppendPackageFileService).not_to receive(:new)
            end

            it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
          end

          context 'an error from the append package file service' do
            let(:create_plugins_xml_service_response) { ServiceResponse.success(payload: { changes_exist: true, empty_plugins: false, metadata_content: 'new metadata' }) }
            let(:append_package_file_service_response) { ServiceResponse.error(message: 'metadata content is not set') }

            before do
              expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
            end

            it_behaves_like 'returning an error service response', message: 'metadata content is not set'
          end

          context 'without a versionless package for plugins' do
            before do
              versionless_package_for_plugins.package_files.update_all(file_name: 'test.txt')
              expect(::Packages::Maven::Metadata::CreatePluginsXmlService).not_to receive(:new)
            end

            it_behaves_like 'returning a success service response', message: 'New metadata package files created'
          end

          context 'without a versionless package for versions' do
            before do
              versionless_package_for_versions.package_files.update_all(file_name: 'test.txt')
              expect(::Packages::Maven::Metadata::CreateVersionsXmlService).not_to receive(:new)
            end

            it_behaves_like 'returning a success service response', message: 'No changes for plugins xml'
          end

          context 'without a metadata package file for plugins' do
            before do
              versionless_package_for_plugins.package_files.update_all(file_name: 'test.txt')
              expect(::Packages::Maven::Metadata::CreatePluginsXmlService).not_to receive(:new)
            end

            it_behaves_like 'returning a success service response', message: 'New metadata package files created'
          end
        end
      end
    end
  end
end
