# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:epoch) }
    it { is_expected.to validate_presence_of(:release) }
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:arch) }

    it { is_expected.to validate_numericality_of(:epoch).only_integer.is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_length_of(:release).is_at_most(128) }
    it { is_expected.to validate_length_of(:summary).is_at_most(1000) }
    it { is_expected.to validate_length_of(:description).is_at_most(5000) }
    it { is_expected.to validate_length_of(:arch).is_at_most(255) }
    it { is_expected.to validate_length_of(:license).is_at_most(1000) }
    it { is_expected.to validate_length_of(:url).is_at_most(1000) }

    describe '#rpm_package_type' do
      it 'will not allow a package with a different package_type' do
        package = build('conan_package')
        rpm_metadatum = build('rpm_metadatum', package: package)

        expect(rpm_metadatum).not_to be_valid
        expect(rpm_metadatum.errors.to_a).to include('Package type must be RPM')
      end
    end
  end
end
