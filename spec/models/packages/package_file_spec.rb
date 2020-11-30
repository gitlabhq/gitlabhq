# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to have_one(:conan_file_metadatum) }
    it { is_expected.to have_many(:package_file_build_infos).inverse_of(:package_file) }
    it { is_expected.to have_many(:pipelines).through(:package_file_build_infos) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end

  context 'with package filenames' do
    let_it_be(:package_file1) { create(:package_file, :xml, file_name: 'FooBar') }
    let_it_be(:package_file2) { create(:package_file, :xml, file_name: 'ThisIsATest') }

    describe '.with_file_name' do
      let(:filename) { 'FooBar' }

      subject { described_class.with_file_name(filename) }

      it { is_expected.to match_array([package_file1]) }
    end

    describe '.with_file_name_like' do
      let(:filename) { 'foobar' }

      subject { described_class.with_file_name_like(filename) }

      it { is_expected.to match_array([package_file1]) }
    end
  end

  context 'updating project statistics' do
    let_it_be(:package, reload: true) { create(:package) }

    context 'when the package file has an explicit size' do
      it_behaves_like 'UpdateProjectStatistics' do
        subject { build(:package_file, :jar, package: package, size: 42) }
      end
    end

    context 'when the package file does not have a size' do
      it_behaves_like 'UpdateProjectStatistics' do
        subject { build(:package_file, package: package, size: nil) }
      end
    end
  end

  describe '.with_conan_package_reference' do
    let_it_be(:non_matching_package_file) { create(:package_file, :nuget) }
    let_it_be(:metadatum) { create(:conan_file_metadatum, :package_file) }
    let_it_be(:reference) { metadatum.conan_package_reference}

    it 'returns matching packages' do
      expect(described_class.with_conan_package_reference(reference))
        .to eq([metadatum.package_file])
    end
  end

  describe '#update_file_store callback' do
    let_it_be(:package_file) { build(:package_file, :nuget, size: nil) }

    subject { package_file.save! }

    it 'updates metadata columns' do
      expect(package_file)
        .to receive(:update_file_store)
        .and_call_original

      # This expectation uses a stub because we can no longer test a change from
      # `nil` to `1`, because the field is no longer nullable, and it defaults
      # to `1`.
      expect(package_file)
        .to receive(:update_column)
        .with(:file_store, ::Packages::PackageFileUploader::Store::LOCAL)

      expect { subject }.to change { package_file.size }.from(nil).to(3513)
    end
  end
end
