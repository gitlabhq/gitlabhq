# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Pypi::Package, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  describe 'relationships' do
    it { is_expected.to have_one(:pypi_metadatum).inverse_of(:package) }
  end

  describe 'validations' do
    describe '#version' do
      it { is_expected.to allow_value('0.1').for(:version) }
      it { is_expected.to allow_value('2.0').for(:version) }
      it { is_expected.to allow_value('1.2.0').for(:version) }
      it { is_expected.to allow_value('0100!0.0').for(:version) }
      it { is_expected.to allow_value('00!1.2').for(:version) }
      it { is_expected.to allow_value('1.0a').for(:version) }
      it { is_expected.to allow_value('1.0-a').for(:version) }
      it { is_expected.to allow_value('1.0.a1').for(:version) }
      it { is_expected.to allow_value('1.0a1').for(:version) }
      it { is_expected.to allow_value('1.0-a1').for(:version) }
      it { is_expected.to allow_value('1.0alpha1').for(:version) }
      it { is_expected.to allow_value('1.0b1').for(:version) }
      it { is_expected.to allow_value('1.0beta1').for(:version) }
      it { is_expected.to allow_value('1.0rc1').for(:version) }
      it { is_expected.to allow_value('1.0pre1').for(:version) }
      it { is_expected.to allow_value('1.0preview1').for(:version) }
      it { is_expected.to allow_value('1.0.dev1').for(:version) }
      it { is_expected.to allow_value('1.0.DEV1').for(:version) }
      it { is_expected.to allow_value('1.0.post1').for(:version) }
      it { is_expected.to allow_value('1.0.rev1').for(:version) }
      it { is_expected.to allow_value('1.0.r1').for(:version) }
      it { is_expected.to allow_value('1.0c2').for(:version) }
      it { is_expected.to allow_value('2012.15').for(:version) }
      it { is_expected.to allow_value('1.0+5').for(:version) }
      it { is_expected.to allow_value('1.0+abc.5').for(:version) }
      it { is_expected.to allow_value('1!1.1').for(:version) }
      it { is_expected.to allow_value('1.0c3').for(:version) }
      it { is_expected.to allow_value('1.0rc2').for(:version) }
      it { is_expected.to allow_value('1.0c1').for(:version) }
      it { is_expected.to allow_value('1.0b2-346').for(:version) }
      it { is_expected.to allow_value('1.0b2.post345').for(:version) }
      it { is_expected.to allow_value('1.0b2.post345.dev456').for(:version) }
      it { is_expected.to allow_value('1.2.rev33+123456').for(:version) }
      it { is_expected.to allow_value('1.1.dev1').for(:version) }
      it { is_expected.to allow_value('1.0b1.dev456').for(:version) }
      it { is_expected.to allow_value('1.0a12.dev456').for(:version) }
      it { is_expected.to allow_value('1.0b2').for(:version) }
      it { is_expected.to allow_value('1.0.dev456').for(:version) }
      it { is_expected.to allow_value('1.0c1.dev456').for(:version) }
      it { is_expected.to allow_value('1.0.post456').for(:version) }
      it { is_expected.to allow_value('1.0.post456.dev34').for(:version) }
      it { is_expected.to allow_value('1.2+123abc').for(:version) }
      it { is_expected.to allow_value('1.2+abc').for(:version) }
      it { is_expected.to allow_value('1.2+abc123').for(:version) }
      it { is_expected.to allow_value('1.2+abc123def').for(:version) }
      it { is_expected.to allow_value('1.2+1234.abc').for(:version) }
      it { is_expected.to allow_value('1.2+123456').for(:version) }
      it { is_expected.to allow_value('1.2.r32+123456').for(:version) }
      it { is_expected.to allow_value('1!1.2.rev33+123456').for(:version) }
      it { is_expected.to allow_value('1.0a12').for(:version) }
      it { is_expected.to allow_value('1.2.3-45+abcdefgh').for(:version) }
      it { is_expected.to allow_value('v1.2.3').for(:version) }
      it { is_expected.not_to allow_value('1.2.3-45-abcdefgh').for(:version) }
      it { is_expected.not_to allow_value('..1.2.3').for(:version) }
      it { is_expected.not_to allow_value('  1.2.3').for(:version) }
      it { is_expected.not_to allow_value("1.2.3  \r\t").for(:version) }
      it { is_expected.not_to allow_value("\r\t 1.2.3").for(:version) }
      it { is_expected.not_to allow_value('1./2.3').for(:version) }
      it { is_expected.not_to allow_value('1.2.3-4/../../').for(:version) }
      it { is_expected.not_to allow_value('1.2.3-4%2e%2e%').for(:version) }
      it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
      it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
    end
  end

  describe '.with_normalized_pypi_name' do
    let_it_be(:pypi_package) { create(:pypi_package, name: 'Foo.bAr---BAZ_buz') }

    subject { described_class.with_normalized_pypi_name('foo-bar-baz-buz') }

    it { is_expected.to match_array([pypi_package]) }
  end

  describe '.preload_pypi_metadatum' do
    let_it_be(:pypi_package) { create(:pypi_package) }

    subject(:packages) { described_class.preload_pypi_metadatum }

    it 'loads pypi metadatum' do
      expect(packages.first.association(:pypi_metadatum)).to be_loaded
    end
  end

  describe '#normalized_pypi_name' do
    let_it_be(:package) { create(:pypi_package) }

    subject { package.normalized_pypi_name }

    where(:package_name, :normalized_name) do
      'ASDF'               | 'asdf'
      'a.B_c-d'            | 'a-b-c-d'
      'a-------b....c___d' | 'a-b-c-d'
    end

    with_them do
      before do
        package.update_column(:name, package_name)
      end

      it { is_expected.to eq(normalized_name) }
    end
  end
end
