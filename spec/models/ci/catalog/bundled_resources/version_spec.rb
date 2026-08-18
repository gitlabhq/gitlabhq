# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResources::Version, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to belong_to(:bundled_resource).class_name('Ci::Catalog::BundledResource').required }
    it { is_expected.to have_many(:components).class_name('Ci::Catalog::BundledResources::Component') }
  end

  describe 'validations' do
    subject { build(:ci_catalog_bundled_resource_version) }

    it { is_expected.to validate_length_of(:semver_prerelease).is_at_most(255) }
  end

  it 'derives semver columns from the semver setter' do
    version = build(:ci_catalog_bundled_resource_version, semver: '2.3.4')

    expect(version.semver_major).to eq(2)
    expect(version.semver_minor).to eq(3)
    expect(version.semver_patch).to eq(4)
  end

  describe 'natural-key uniqueness' do
    it 'rejects a duplicate stable version (null prerelease) for the same resource' do
      resource = create(:ci_catalog_bundled_resource)
      create(:ci_catalog_bundled_resource_version, bundled_resource: resource, semver: '1.0.0')

      expect do
        create(:ci_catalog_bundled_resource_version, bundled_resource: resource, semver: '1.0.0')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
