# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageFileable, type: :model, feature_category: :package_registry do
  let_it_be(:instance) { build(:conan_recipe_revision) }

  describe 'associations' do
    subject { instance }

    it 'has many file_metadata' do
      is_expected.to have_many(:file_metadata)
    end

    it 'has many package_files through file_metadata' do
      is_expected.to have_many(:package_files).through(:file_metadata)
    end
  end

  describe '#orphan?' do
    subject { instance.orphan? }

    context 'when package_files is empty' do
      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when package_files is not empty' do
      let_it_be(:package_file) do
        create(:conan_package_file, :conan_recipe_file, package: instance.package, conan_recipe_revision: instance)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end
end
