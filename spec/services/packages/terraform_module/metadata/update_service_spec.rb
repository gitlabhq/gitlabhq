# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::UpdateService, feature_category: :package_registry do
  let_it_be(:package) { create(:terraform_module_package, :with_metadatum, without_package_files: true) }

  let(:metadata_hash) { Gitlab::Json.parse(fixture_file('packages/terraform_module/metadata.json')) }
  let(:service) { described_class.new(package, metadata_hash) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'with valid metadata' do
      it 'updates the existing metadata' do
        expect { execute }.to change {
          package.terraform_module_metadatum.fields
        }.from(package.terraform_module_metadatum.fields).to(metadata_hash)

        expect(execute).to be_success
      end
    end

    context 'with invalid metadata' do
      let(:metadata_hash) { { foo: 'bar' } }

      it 'does not update metadata and tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(ActiveRecord::RecordInvalid),
          class: described_class.name,
          package_id: package.id
        )

        expect { execute }.not_to change { package.terraform_module_metadatum.reset.fields }
        expect(execute).to be_error
      end
    end
  end
end
