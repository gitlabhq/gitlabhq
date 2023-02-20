# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:target_sha) }
    it { is_expected.to validate_presence_of(:composer_json) }

    describe '#composer_package_type' do
      subject { build(:composer_metadatum, package: package) }

      shared_examples 'an invalid record' do
        it do
          expect(subject).not_to be_valid
          expect(subject.errors.to_a).to include('Package type must be Composer')
        end
      end

      context 'when the metadatum package_type is Composer' do
        let(:package) { build(:composer_package) }

        it { is_expected.to be_valid }
      end

      context 'when the metadatum has no associated package' do
        let(:package) { nil }

        it_behaves_like 'an invalid record'
      end

      context 'when the metadatum package_type is not Composer' do
        let(:package) { build(:npm_package) }

        it_behaves_like 'an invalid record'
      end
    end
  end

  describe 'scopes' do
    let_it_be(:package_name) { 'sample-project' }
    let_it_be(:json) { { 'name' => package_name } }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }
    let_it_be(:package1) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
    let_it_be(:package2) { create(:composer_package, :with_metadatum, project: project, name: 'other-name', version: '1.0.0', json: json) }
    let_it_be(:package3) { create(:pypi_package, name: package_name, project: project) }

    describe '.for_package' do
      subject { described_class.for_package(package_name, project.id) }

      it { is_expected.to eq [package1.composer_metadatum] }
    end
  end
end
