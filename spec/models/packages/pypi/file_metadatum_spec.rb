# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::FileMetadatum, feature_category: :package_registry do
  describe 'associations' do
    it 'belongs to package file' do
      is_expected.to belong_to(:package_file).inverse_of(:pypi_file_metadatum)
        .class_name('Packages::PackageFile').optional(false)
    end

    it 'belongs to project' do
      is_expected.to belong_to(:project).optional(false)
    end
  end

  describe 'validations' do
    subject(:pypi_file_metadatum) { build(:pypi_file_metadatum) }

    it { is_expected.to allow_value('').for(:required_python) }

    it 'validates required_python' do
      is_expected.to validate_length_of(:required_python).is_at_most(
        Packages::Pypi::Metadatum::MAX_REQUIRED_PYTHON_LENGTH
      )
    end

    context 'when package file is not of type PyPI' do
      before do
        allow(pypi_file_metadatum.package_file).to receive_message_chain(:package, :pypi?).and_return(false)
      end

      it 'is not valid' do
        expect(pypi_file_metadatum).not_to be_valid
        expect(pypi_file_metadatum.errors[:package_file]).to include('Package type must be PyPI')
      end
    end
  end
end
