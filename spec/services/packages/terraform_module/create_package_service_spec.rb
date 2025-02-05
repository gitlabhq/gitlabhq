# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::CreatePackageService, feature_category: :package_registry do
  let_it_be_with_reload(:namespace) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:sha256) { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
  let_it_be_with_reload(:package_settings) { create(:namespace_package_setting, namespace: namespace) }

  let(:overrides) { {} }

  let(:params) do
    {
      module_name: 'foo',
      module_system: 'bar',
      module_version: '1.0.1',
      file: UploadedFile.new(Tempfile.new('test').path, sha256: sha256),
      file_name: 'foo-bar-1.0.1.tgz'
    }.merge(overrides)
  end

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    shared_examples 'creating a package' do
      it 'creates a package' do
        expect(::Packages::TerraformModule::ProcessPackageFileWorker).to receive(:perform_async).once

        expect { subject }.to change { ::Packages::TerraformModule::Package.count }.by(1)
      end
    end

    shared_examples 'duplicate package error' do
      it 'returns duplicate package error' do
        is_expected.to be_error.and have_attributes(
          reason: :forbidden,
          message: 'A module with the same name already exists in the namespace.'
        )
      end
    end

    shared_examples 'with duplicate regex exception, allow creation of matching package' do
      before do
        package_settings.update_columns(terraform_module_duplicate_exception_regex: regex)
      end

      context 'when regex matches' do
        let(:regex) { ".*#{existing_package.name.last(3)}.*" }

        it_behaves_like 'creating a package'
      end

      context 'when regex does not match' do
        let(:regex) { '.*not-a-match.*' }

        it_behaves_like 'duplicate package error'
      end
    end

    shared_examples 'with duplicate regex exception, prevent creation of matching package' do
      before do
        package_settings.update_columns(terraform_module_duplicate_exception_regex: regex)
      end

      context 'when regex matches' do
        let(:regex) { ".*#{existing_package.name.last(3)}.*" }

        it_behaves_like 'duplicate package error'
      end

      context 'when regex does not match' do
        let(:regex) { '.*not-a-match.*' }

        it_behaves_like 'creating a package'
      end
    end

    context 'when valid package' do
      it_behaves_like 'creating a package'
    end

    context 'when package already exists elsewhere' do
      let(:project2) { create(:project, namespace: namespace) }
      let!(:existing_package) do
        create(:terraform_module_package, project: project2, name: 'foo/bar', version: '1.0.0')
      end

      context 'when duplicates not allowed' do
        before do
          package_settings.update_column(:terraform_module_duplicates_allowed, false)
        end

        it_behaves_like 'duplicate package error'
        it_behaves_like 'with duplicate regex exception, allow creation of matching package'
      end

      context 'when duplicates allowed' do
        before do
          package_settings.update_column(:terraform_module_duplicates_allowed, true)
        end

        it_behaves_like 'creating a package'
        it_behaves_like 'with duplicate regex exception, prevent creation of matching package'
      end

      context 'for ancestor namespace' do
        let_it_be_with_reload(:package_settings) { create(:namespace_package_setting, :group) }
        let_it_be_with_reload(:parent_namespace) { package_settings.namespace }

        before do
          namespace.update!(parent: parent_namespace)
        end

        context 'when duplicates allowed in an ancestor' do
          before do
            package_settings.update_column(:terraform_module_duplicates_allowed, true)
          end

          it_behaves_like 'creating a package'
        end

        context 'when duplicates allowed in an ancestor with exception' do
          before do
            package_settings.update_columns(
              terraform_module_duplicates_allowed: true,
              terraform_module_duplicate_exception_regex: ".*#{existing_package.name.last(3)}.*"
            )
          end

          it_behaves_like 'duplicate package error'
        end
      end

      context 'when marked as pending_destruction' do
        before do
          existing_package.pending_destruction!
        end

        it_behaves_like 'creating a package'
      end
    end

    context 'when version already exists' do
      let!(:existing_version) { create(:terraform_module_package, project: project, name: 'foo/bar', version: '1.0.1') }

      it 'returns error' do
        is_expected.to be_error.and have_attributes(
          reason: :forbidden,
          message: 'A module with the same name & version already exists in the project.'
        )
      end

      context 'when marked as pending_destruction' do
        before do
          existing_version.pending_destruction!
        end

        it_behaves_like 'creating a package'
      end
    end

    context 'with empty version' do
      let(:overrides) { { module_version: '' } }

      it { is_expected.to be_error.and have_attributes(reason: :bad_request, message: 'Version is empty.') }
    end

    context 'with invalid name' do
      let(:overrides) { { module_name: 'foo@bar' } }

      it 'returns validation error' do
        is_expected.to be_error.and have_attributes(
          reason: :unprocessable_entity,
          message: 'Validation failed: Name is invalid'
        )
      end
    end
  end
end
