# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::CreateService, feature_category: :package_registry do
  let_it_be(:package) { create(:terraform_module_package) }
  let_it_be(:metadata_hash) { Gitlab::Json.parse(fixture_file('packages/terraform_module/metadata.json')) }
  let(:service) { described_class.new(package, metadata_hash) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'with valid metadata' do
      it { is_expected.to be_success }

      it 'creates a new metadata' do
        expect { execute }.to change { Packages::TerraformModule::Metadatum.count }.by(1)
        expect(package.terraform_module_metadatum.fields).to eq(metadata_hash)
      end

      context 'when terraform_extract_terraform_package_model is disabled' do
        let_it_be(:package) { create(:terraform_module_package_legacy) }

        before do
          stub_feature_flags(terraform_extract_terraform_package_model: false)
        end

        it 'creates a new metadata' do
          expect { execute }.to change { Packages::TerraformModule::Metadatum.count }.by(1)
          expect(package.terraform_module_metadatum.fields).to eq(metadata_hash)
        end
      end
    end

    context 'with existing metadata' do
      context 'when terraform_extract_terraform_package_model is enabled' do
        before do
          create(:terraform_module_metadatum, package: package)
        end

        it 'updates the existing metadata' do
          expect(package.terraform_module_metadatum.fields).not_to eq(metadata_hash)

          expect { execute }.not_to change { Packages::TerraformModule::Metadatum.count }
          expect(execute).to be_success
          expect(package.terraform_module_metadatum.fields).to eq(metadata_hash)
        end
      end

      context 'when terraform_extract_terraform_package_model is disabled' do
        let_it_be(:package) { create(:terraform_module_package_legacy) }

        before do
          create(:terraform_module_metadatum, legacy_package: package)
          stub_feature_flags(terraform_extract_terraform_package_model: false)
        end

        it 'updates the existing metadata' do
          expect(package.terraform_module_metadatum.fields).not_to eq(metadata_hash)

          expect { execute }.not_to change { Packages::TerraformModule::Metadatum.count }
          expect(execute).to be_success
          expect(package.terraform_module_metadatum.fields).to eq(metadata_hash)
        end
      end
    end

    context 'with invalid metadata' do
      let(:metadata_hash) { { foo: 'bar' } }

      it 'does not create a new metadata and tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(ActiveRecord::RecordInvalid),
          class: described_class.name,
          package_id: package.id
        )

        expect { execute }.not_to change { Packages::TerraformModule::Metadatum.count }
        expect(execute).to be_error
      end

      context 'when terraform_extract_terraform_package_model is disabled' do
        let_it_be(:package) { create(:terraform_module_package_legacy) }

        before do
          stub_feature_flags(terraform_extract_terraform_package_model: false)
        end

        it 'does not create a new metadata and tracks the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(ActiveRecord::RecordInvalid),
            class: described_class.name,
            package_id: package.id
          )

          expect { execute }.not_to change { Packages::TerraformModule::Metadatum.count }
          expect(execute).to be_error
        end
      end
    end
  end
end
