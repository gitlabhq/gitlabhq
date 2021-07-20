# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_file1) { create(:package_file, :xml, file_name: 'FooBar') }
  let_it_be(:package_file2) { create(:package_file, :xml, file_name: 'ThisIsATest') }
  let_it_be(:package_file3) { create(:package_file, :xml, file_name: 'formatted.zip') }
  let_it_be(:debian_package) { create(:debian_package, project: project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to have_one(:conan_file_metadatum) }
    it { is_expected.to have_many(:package_file_build_infos).inverse_of(:package_file) }
    it { is_expected.to have_many(:pipelines).through(:package_file_build_infos) }
    it { is_expected.to have_one(:debian_file_metadatum).inverse_of(:package_file).class_name('Packages::Debian::FileMetadatum') }
    it { is_expected.to have_one(:helm_file_metadatum).inverse_of(:package_file).class_name('Packages::Helm::FileMetadatum') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end

  context 'with package filenames' do
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

    describe '.with_format' do
      subject { described_class.with_format('zip') }

      it { is_expected.to contain_exactly(package_file3) }
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

  describe '.for_package_ids' do
    it 'returns matching packages' do
      expect(described_class.for_package_ids([package_file1.package.id, package_file2.package.id]))
        .to contain_exactly(package_file1, package_file2)
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

  describe '.for_rubygem_with_file_name' do
    let_it_be(:non_ruby_package) { create(:nuget_package, project: project, package_type: :nuget) }
    let_it_be(:ruby_package) { create(:rubygems_package, project: project, package_type: :rubygems) }
    let_it_be(:file_name) { 'other.gem' }

    let_it_be(:non_ruby_file) { create(:package_file, :nuget, package: non_ruby_package, file_name: file_name) }
    let_it_be(:gem_file1) { create(:package_file, :gem, package: ruby_package) }
    let_it_be(:gem_file2) { create(:package_file, :gem, package: ruby_package, file_name: file_name) }

    it 'returns the matching gem file only for ruby packages' do
      expect(described_class.for_rubygem_with_file_name(project, file_name)).to contain_exactly(gem_file2)
    end
  end

  context 'Debian scopes' do
    let_it_be(:debian_changes) { debian_package.package_files.last }
    let_it_be(:debian_deb) { create(:debian_package_file, package: debian_package)}
    let_it_be(:debian_udeb) { create(:debian_package_file, :udeb, package: debian_package)}

    let_it_be(:debian_contrib) do
      create(:debian_package_file, package: debian_package).tap do |pf|
        pf.debian_file_metadatum.update!(component: 'contrib')
      end
    end

    let_it_be(:debian_mipsel) do
      create(:debian_package_file, package: debian_package).tap do |pf|
        pf.debian_file_metadatum.update!(architecture: 'mipsel')
      end
    end

    describe '#with_debian_file_type' do
      it { expect(described_class.with_debian_file_type(:changes)).to contain_exactly(debian_changes) }
    end

    describe '#with_debian_component_name' do
      it { expect(described_class.with_debian_component_name('contrib')).to contain_exactly(debian_contrib) }
    end

    describe '#with_debian_architecture_name' do
      it { expect(described_class.with_debian_architecture_name('mipsel')).to contain_exactly(debian_mipsel) }
    end
  end

  describe '.for_helm_with_channel' do
    let_it_be(:project) { create(:project) }
    let_it_be(:non_helm_package) { create(:nuget_package, project: project, package_type: :nuget) }
    let_it_be(:helm_package1) { create(:helm_package, project: project, package_type: :helm) }
    let_it_be(:helm_package2) { create(:helm_package, project: project, package_type: :helm) }
    let_it_be(:channel) { 'some-channel' }

    let_it_be(:non_helm_file) { create(:package_file, :nuget, package: non_helm_package) }
    let_it_be(:helm_file1) { create(:helm_package_file, package: helm_package1) }
    let_it_be(:helm_file2) { create(:helm_package_file, package: helm_package2, channel: channel) }

    it 'returns the matching file only for Helm packages' do
      expect(described_class.for_helm_with_channel(project, channel)).to contain_exactly(helm_file2)
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
