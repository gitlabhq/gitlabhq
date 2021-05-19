# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::FileMetadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }
  end

  describe 'validations' do
    describe '#package_file' do
      it { is_expected.to validate_presence_of(:package_file) }
    end

    describe '#valid_helm_package_type' do
      let_it_be_with_reload(:helm_package_file) { create(:helm_package_file) }

      let(:helm_file_metadatum) { helm_package_file.helm_file_metadatum }

      before do
        helm_package_file.package.package_type = :pypi
      end

      it 'validates package of type helm' do
        expect(helm_file_metadatum).not_to be_valid
        expect(helm_file_metadatum.errors.to_a).to contain_exactly('Package file Package type must be Helm')
      end
    end

    describe '#channel' do
      it 'validates #channel', :aggregate_failures do
        is_expected.to validate_presence_of(:channel)

        is_expected.to allow_value('a' * 63).for(:channel)
        is_expected.not_to allow_value('a' * 64).for(:channel)

        is_expected.to allow_value('release').for(:channel)
        is_expected.to allow_value('my-repo').for(:channel)
        is_expected.to allow_value('my-repo42').for(:channel)

        # Do not allow empty
        is_expected.not_to allow_value('').for(:channel)

        # Do not allow Unicode
        is_expected.not_to allow_value('hé').for(:channel)
      end
    end

    describe '#metadata' do
      it 'validates #metadata', :aggregate_failures do
        is_expected.not_to validate_presence_of(:metadata)
        is_expected.to allow_value({ 'name': 'foo', 'version': 'v1.0', 'apiVersion': 'v2' }).for(:metadata)
        is_expected.not_to allow_value({}).for(:metadata)
        is_expected.not_to allow_value({ 'version': 'v1.0', 'apiVersion': 'v2' }).for(:metadata)
        is_expected.not_to allow_value({ 'name': 'foo', 'apiVersion': 'v2' }).for(:metadata)
        is_expected.not_to allow_value({ 'name': 'foo', 'version': 'v1.0' }).for(:metadata)
      end
    end
  end
end
