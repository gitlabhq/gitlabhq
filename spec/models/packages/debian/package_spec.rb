# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::Package, type: :model, feature_category: :package_registry do
  describe 'associations' do
    it { is_expected.to have_one(:publication).inverse_of(:package).class_name('Packages::Debian::Publication') }

    it do
      is_expected.to have_one(:distribution)
        .through(:publication)
        .source(:distribution)
        .inverse_of(:packages)
        .class_name('Packages::Debian::ProjectDistribution')
    end
  end

  describe 'delegates' do
    it { is_expected.to delegate_method(:codename).to(:distribution).with_prefix(:distribution) }
    it { is_expected.to delegate_method(:suite).to(:distribution).with_prefix(:distribution) }
  end

  describe '.with_codename' do
    let_it_be(:publication) { create(:debian_publication) }

    subject { described_class.with_codename(publication.distribution.codename).to_a }

    it { is_expected.to contain_exactly(publication.package) }
  end

  describe '.with_codename_or_suite' do
    let_it_be(:distribution1) { create(:debian_project_distribution, :with_suite) }
    let_it_be(:distribution2) { create(:debian_project_distribution, :with_suite) }

    let_it_be(:package1) { create(:debian_package, published_in: distribution1) }
    let_it_be(:package2) { create(:debian_package, published_in: distribution2) }

    context 'with a codename' do
      subject { described_class.with_codename_or_suite(distribution1.codename).to_a }

      it { is_expected.to contain_exactly(package1) }
    end

    context 'with a suite' do
      subject { described_class.with_codename_or_suite(distribution2.suite).to_a }

      it { is_expected.to contain_exactly(package2) }
    end
  end

  describe 'validations' do
    describe '#name' do
      subject { build(:debian_package) }

      it { is_expected.to allow_value('0ad').for(:name) }
      it { is_expected.to allow_value('g++').for(:name) }
      it { is_expected.not_to allow_value('a_b').for(:name) }

      context 'when debian incoming' do
        subject { create(:debian_incoming) }

        # Only 'incoming' is accepted
        it { is_expected.to allow_value('incoming').for(:name) }
        it { is_expected.not_to allow_value('0ad').for(:name) }
        it { is_expected.not_to allow_value('g++').for(:name) }
        it { is_expected.not_to allow_value('a_b').for(:name) }
      end
    end

    describe '#version' do
      subject { build(:debian_package) }

      it { is_expected.to allow_value('2:4.9.5+dfsg-5+deb10u1').for(:version) }
      it { is_expected.not_to allow_value('1_0').for(:version) }

      context 'when debian incoming' do
        subject { create(:debian_incoming) }

        it { is_expected.to allow_value(nil).for(:version) }
        it { is_expected.not_to allow_value('2:4.9.5+dfsg-5+deb10u1').for(:version) }
        it { is_expected.not_to allow_value('1_0').for(:version) }
      end
    end

    describe 'uniqueness for package type debian' do
      let_it_be(:package) { create(:debian_package) }

      it 'does not allow a Debian package with same project, name, version and distribution' do
        new_package = build(:debian_package, project: package.project, name: package.name, version: package.version)
        new_package.publication.distribution = package.publication.distribution
        expect(new_package).not_to be_valid
        expect(new_package.errors.to_a).to include('Name has already been taken')
      end

      it 'does not allow a Debian package with same project, name, version, but no distribution' do
        new_package = build(:debian_package, project: package.project, name: package.name, version: package.version,
          published_in: nil)
        expect(new_package).not_to be_valid
        expect(new_package.errors.to_a).to include('Name has already been taken')
      end

      context 'with pending_destruction package' do
        let_it_be(:package) { create(:debian_package, :pending_destruction) }

        it 'allows a Debian package with same project, name, version and distribution' do
          new_package = build(:debian_package, project: package.project, name: package.name, version: package.version)
          new_package.publication.distribution = package.publication.distribution
          expect(new_package).to be_valid
        end
      end
    end
  end

  describe '.preload_debian_file_metadata' do
    let_it_be(:debian_package) { create(:debian_package) }

    subject(:packages) { described_class.preload_debian_file_metadata }

    it 'preloads package files' do
      expect(packages.first.association(:package_files)).to be_loaded
    end

    it 'preloads debian files metadata' do
      expect(packages.first.package_files.first.association(:debian_file_metadatum)).to be_loaded
    end
  end

  describe '.incoming_package!' do
    let_it_be(:debian_package) { create(:debian_package) }
    let_it_be(:debian_processing_incoming) { create(:debian_incoming, :processing) }

    subject(:incoming_packages) { described_class.incoming_package! }

    context 'when incoming exists' do
      let_it_be(:debian_incoming) { create(:debian_incoming) }

      it { is_expected.to eq(debian_incoming) }
    end

    context 'when incoming not found' do
      it { expect { incoming_packages }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe '.existing_packages_with' do
    let_it_be(:name) { 'my-package' }
    let_it_be(:version) { '1.0.0' }
    let_it_be(:package1) { create(:debian_package, name: name, version: version) }
    let_it_be(:package2) { create(:debian_package) }

    subject { described_class.existing_packages_with(name: name, version: version) }

    it { is_expected.to contain_exactly(package1) }
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :debian_package
  end

  describe '#incoming?' do
    let(:package) { build(:debian_package) }

    subject { package.incoming? }

    it { is_expected.to eq(false) }

    context 'with debian_incoming' do
      let(:package) { create(:debian_incoming) }

      it { is_expected.to eq(true) }
    end
  end
end
