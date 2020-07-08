# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Pypi::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    describe '#pypi_package_type' do
      it 'will not allow a package with a different package_type' do
        package = build('package')
        pypi_metadatum = build('pypi_metadatum', package: package)

        expect(pypi_metadatum).not_to be_valid
        expect(pypi_metadatum.errors.to_a).to include('Package type must be PyPi')
      end
    end
  end
end
