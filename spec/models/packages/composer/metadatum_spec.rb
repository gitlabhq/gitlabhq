# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Composer::Package').inverse_of(:composer_metadatum) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:target_sha) }
    it { is_expected.to validate_presence_of(:composer_json) }
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
