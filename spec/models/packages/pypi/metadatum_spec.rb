# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }

    # TODO: Remove with the rollout of the FF pypi_extract_pypi_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
    it do
      is_expected.to belong_to(:legacy_package).conditions(package_type: :pypi).class_name('Packages::Package')
        .inverse_of(:pypi_metadatum).with_foreign_key(:package_id)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    # TODO: Remove with the rollout of the FF pypi_extract_pypi_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
    it { is_expected.not_to validate_presence_of(:legacy_package) }

    context 'when pypi_extract_package_model is disabled' do
      before do
        stub_feature_flags(pypi_extract_pypi_package_model: false)
      end

      it { is_expected.to validate_presence_of(:legacy_package) }
      it { is_expected.not_to validate_presence_of(:package) }
    end

    it { is_expected.to allow_value('').for(:required_python) }
    it { is_expected.to validate_length_of(:required_python).is_at_most(described_class::MAX_REQUIRED_PYTHON_LENGTH) }
    it { is_expected.to allow_value('').for(:keywords) }
    it { is_expected.to allow_value(nil).for(:keywords) }
    it { is_expected.to validate_length_of(:keywords).is_at_most(described_class::MAX_KEYWORDS_LENGTH) }
    it { is_expected.to allow_value('').for(:metadata_version) }
    it { is_expected.to allow_value(nil).for(:metadata_version) }
    it { is_expected.to validate_length_of(:metadata_version).is_at_most(described_class::MAX_METADATA_VERSION_LENGTH) }
    it { is_expected.to allow_value('').for(:author_email) }
    it { is_expected.to allow_value(nil).for(:author_email) }
    it { is_expected.to validate_length_of(:author_email).is_at_most(described_class::MAX_AUTHOR_EMAIL_LENGTH) }
    it { is_expected.to allow_value('').for(:summary) }
    it { is_expected.to allow_value(nil).for(:summary) }
    it { is_expected.to validate_length_of(:summary).is_at_most(described_class::MAX_SUMMARY_LENGTH) }
    it { is_expected.to allow_value('').for(:description) }
    it { is_expected.to allow_value(nil).for(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(described_class::MAX_DESCRIPTION_LENGTH) }
    it { is_expected.to allow_value('').for(:description_content_type) }
    it { is_expected.to allow_value(nil).for(:description_content_type) }

    it {
      is_expected.to validate_length_of(:description_content_type)
        .is_at_most(described_class::MAX_DESCRIPTION_CONTENT_TYPE_LENGTH)
    }

    describe '#pypi_package_type', :aggregate_failures do
      subject(:pypi_metadatum) { build(:pypi_metadatum) }

      it 'builds a valid metadatum' do
        expect { pypi_metadatum }.not_to raise_error
        expect(pypi_metadatum).to be_valid
      end

      context 'with a different package type' do
        let(:package) { build(:package) }

        it 'raises the error' do
          expect { build(:pypi_metadatum, package: package) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
        end

        context 'when pypi_extract_package_model is disabled' do
          before do
            stub_feature_flags(pypi_extract_pypi_package_model: false)
          end

          it 'adds the validation error' do
            pypi_metadatum = build(:pypi_metadatum, legacy_package: package, package: nil)

            expect(pypi_metadatum).not_to be_valid
            expect(pypi_metadatum.errors.to_a).to include('Package type must be PyPi')
          end
        end
      end
    end
  end
end
