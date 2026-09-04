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

  describe 'external readme storage' do
    let_it_be_with_reload(:version) { create(:ci_catalog_bundled_resource_version) }

    it 'persists the readme to object storage and reads it back' do
      version.update!(readme: '**bold text**')

      expect(described_class.find(version.id).readme).to eq('**bold text**')
    end

    it 'reads back a version that has no readme', :aggregate_failures do
      fresh = described_class.find(create(:ci_catalog_bundled_resource_version).id)

      expect(fresh.readme).to be_nil
      expect(fresh.readme_html).to eq('')
    end

    it 'clears a stored readme when it is set to nil', :aggregate_failures do
      version.update!(readme: '# Widgets')
      described_class.find(version.id).update!(readme: nil)

      cleared = described_class.find(version.id)
      expect(cleared.readme).to be_nil
      expect(cleared.readme_html).to eq('')
    end

    it 'caches the rendered readme_html in object storage' do
      version.update!(readme: '**bold**')

      reloaded = described_class.find(version.id)
      expect(reloaded.readme_html).to include('<strong')
      expect(reloaded.readme_html).to include('bold</strong>')
    end

    it 'keeps the readme out of Postgres', :aggregate_failures do
      version.update!(readme: '# Widgets')

      row = described_class.connection.select_one(
        "SELECT readme, readme_html FROM catalog_bundled_resource_versions WHERE id = #{version.id.to_i}"
      )

      expect(row['readme']).to be_nil
      expect(row['readme_html']).to be_nil
    end

    it 'removes the stored readme when the version is destroyed' do
      version.update!(readme: 'to be deleted')
      stored_path = version.send(:external_storage_uploader).path

      expect(File.exist?(stored_path)).to be true

      version.destroy!

      expect(File.exist?(stored_path)).to be false
    end
  end
end
