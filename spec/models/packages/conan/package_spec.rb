# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::Package, type: :model, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package) }

  describe 'relationships' do
    it { is_expected.to have_one(:conan_metadatum).inverse_of(:package) }

    it do
      is_expected.to have_many(:conan_recipe_revisions).inverse_of(:package)
        .class_name('Packages::Conan::RecipeRevision')
    end

    it do
      is_expected.to have_many(:conan_package_references).inverse_of(:package)
        .class_name('Packages::Conan::PackageReference')
    end

    it do
      is_expected.to have_many(:conan_package_revisions).inverse_of(:package)
        .class_name('Packages::Conan::PackageRevision')
    end
  end

  describe 'validations' do
    subject { build_stubbed(:conan_package) }

    describe '#name' do
      let(:fifty_one_characters) { 'f_b' * 17 }

      it { is_expected.to allow_value('foo+bar').for(:name) }
      it { is_expected.to allow_value('foo_bar').for(:name) }
      it { is_expected.to allow_value('foo.bar').for(:name) }
      it { is_expected.to allow_value('9foo+bar').for(:name) }
      it { is_expected.not_to allow_value(fifty_one_characters).for(:name) }
      it { is_expected.not_to allow_value('+foobar').for(:name) }
      it { is_expected.not_to allow_value('.foobar').for(:name) }
      it { is_expected.not_to allow_value('%foo%bar').for(:name) }
    end

    describe '#version' do
      let(:fifty_one_characters) { '1.2' * 17 }

      it { is_expected.to allow_value('1.2').for(:version) }
      it { is_expected.to allow_value('1.2.3-beta').for(:version) }
      it { is_expected.to allow_value('1.2.3-pre1+build2').for(:version) }
      it { is_expected.not_to allow_value('1').for(:version) }
      it { is_expected.not_to allow_value(fifty_one_characters).for(:version) }
      it { is_expected.not_to allow_value('1./2.3').for(:version) }
      it { is_expected.not_to allow_value('.1.2.3').for(:version) }
      it { is_expected.not_to allow_value('+1.2.3').for(:version) }
      it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
    end

    context 'for recipe uniqueness' do
      let(:new_package) do
        build(:conan_package, project: package.project, name: package.name, version: package.version)
      end

      it 'does not allow a conan package with same recipe' do
        expect(new_package).not_to be_valid
        expect(new_package.errors.to_a).to include('Package recipe already exists')
      end

      it 'allows a conan package with same project, name, version and package_type but different channel' do
        new_package.conan_metadatum.package_channel = 'beta'
        expect(new_package).to be_valid
      end

      it 'allows a conan package with same project, name, version and package_type, but different package username' do
        new_package.conan_metadatum.package_username = 'asdf99'
        expect(new_package).to be_valid
      end

      context 'with pending destruction package' do
        let_it_be(:package) { create(:conan_package, :pending_destruction) }

        it 'allows a conan package with same recipe' do
          expect(new_package).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '.with_conan_channel' do
      subject { described_class.with_conan_channel('stable') }

      it 'includes only packages with specified version' do
        is_expected.to include(package)
      end
    end

    describe '.with_conan_username' do
      subject do
        described_class.with_conan_username(
          Packages::Conan::Metadatum.package_username_from(full_path: package.project.full_path)
        )
      end

      it 'includes only packages with specified version' do
        is_expected.to match_array([package])
      end
    end

    describe '.preload_conan_metadatum' do
      subject(:packages) { described_class.preload_conan_metadatum }

      it 'loads conan metadatum' do
        expect(packages.first.association(:conan_metadatum)).to be_loaded
      end
    end

    describe '.installable' do
      it_behaves_like 'installable packages', :conan_package
    end
  end

  describe '#latest_recipe_revision_or_default' do
    subject(:revision) { package.latest_recipe_revision_or_default }

    context 'when package has recipe revisions' do
      it 'returns the last recipe revision' do
        expect(revision).to eq(package.conan_recipe_revisions.last)
      end
    end

    context 'when package does not have recipe revisions' do
      let_it_be(:package) { create(:conan_package, without_revisions: true) }

      it 'returns default recipe revision' do
        expect(revision).to be_a(::Packages::Conan::RecipeRevision)
          .and have_attributes(revision: ::Packages::Conan::FileMetadatum::DEFAULT_REVISION, package_id: package.id)
      end
    end
  end

  describe '#default_recipe_revision' do
    let_it_be(:package) { create(:conan_package, without_revisions: true) }

    subject(:revision) { package.default_recipe_revision }

    it 'returns default recipe revision' do
      expect(revision).to be_a(::Packages::Conan::RecipeRevision)
        .and have_attributes(revision: ::Packages::Conan::FileMetadatum::DEFAULT_REVISION, package_id: package.id)
    end
  end

  describe '#default_package_revision' do
    subject(:revision) { package.default_package_revision }

    it 'returns default package revision' do
      expect(revision).to be_a(::Packages::Conan::PackageRevision)
        .and have_attributes(revision: ::Packages::Conan::FileMetadatum::DEFAULT_REVISION, package_id: package.id)
    end
  end
end
