# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::TerraformModule::CreatePackageService, feature_category: :package_registry do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:sha256) { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
  let_it_be(:package_settings) { create(:namespace_package_setting, namespace: namespace) }

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

        expect { subject }
          .to change { ::Packages::Package.count }.by(1)
          .and change { ::Packages::Package.terraform_module.count }.by(1)
      end
    end

    context 'valid package' do
      it_behaves_like 'creating a package'

      context 'when index_terraform_module_archive feature flag is disabled' do
        before do
          stub_feature_flags(index_terraform_module_archive: false)
        end

        it 'does not enqueue the ProcessPackageFileWorker' do
          expect(::Packages::TerraformModule::ProcessPackageFileWorker).not_to receive(:perform_async)

          subject
        end
      end
    end

    context 'package already exists elsewhere' do
      let(:project2) { create(:project, namespace: namespace) }
      let!(:existing_package) do
        create(:terraform_module_package, project: project2, name: 'foo/bar', version: '1.0.0')
      end

      context 'when duplicates not allowed' do
        it { expect(subject.reason).to eq :forbidden }
        it { expect(subject.message).to be 'A package with the same name already exists in the namespace' }
      end

      context 'when duplicates allowed' do
        before do
          package_settings.update_column(:terraform_module_duplicates_allowed, true)
        end

        it_behaves_like 'creating a package'
      end

      context 'with duplicate regex exception' do
        before do
          package_settings.update_columns(
            terraform_module_duplicates_allowed: false,
            terraform_module_duplicate_exception_regex: regex
          )
        end

        context 'when regex matches' do
          let(:regex) { ".*#{existing_package.name.last(3)}.*" }

          it_behaves_like 'creating a package'
        end

        context 'when regex does not match' do
          let(:regex) { '.*not-a-match.*' }

          it { expect(subject.reason).to eq :forbidden }
          it { expect(subject.message).to be 'A package with the same name already exists in the namespace' }
        end
      end

      context 'for ancestor namespace' do
        let_it_be(:package_settings) { create(:namespace_package_setting, :group) }
        let_it_be(:parent_namespace) { package_settings.namespace }

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
              terraform_module_duplicates_allowed: false,
              terraform_module_duplicate_exception_regex: ".*#{existing_package.name.last(3)}.*"
            )
          end

          it_behaves_like 'creating a package'
        end
      end

      context 'marked as pending_destruction' do
        before do
          existing_package.pending_destruction!
        end

        it_behaves_like 'creating a package'
      end
    end

    context 'version already exists' do
      let!(:existing_version) { create(:terraform_module_package, project: project, name: 'foo/bar', version: '1.0.1') }

      it { expect(subject[:reason]).to eq :forbidden }
      it { expect(subject[:message]).to be 'Package version already exists.' }

      context 'marked as pending_destruction' do
        before do
          existing_version.pending_destruction!
        end

        it_behaves_like 'creating a package'
      end
    end

    context 'with empty version' do
      let(:overrides) { { module_version: '' } }

      it { expect(subject[:reason]).to eq :bad_request }
      it { expect(subject[:message]).to eq 'Version is empty.' }
    end
  end
end
