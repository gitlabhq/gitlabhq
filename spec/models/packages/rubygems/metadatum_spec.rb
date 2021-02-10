# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rubygems::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    describe '#rubygems_package_type' do
      it 'will not allow a package with a different package_type' do
        package = build('conan_package')
        rubygems_metadatum = build('rubygems_metadatum', package: package)

        expect(rubygems_metadatum).not_to be_valid
        expect(rubygems_metadatum.errors.to_a).to include('Package type must be RubyGems')
      end
    end
  end
end
