# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::PackageMetadataPresenter do
  include_context 'with expected presenters dependency groups'

  let_it_be(:package) { create(:nuget_package, :with_symbol_package, :with_metadatum) }
  let_it_be(:tag1) { create(:packages_tag, name: 'tag1', package: package) }
  let_it_be(:tag2) { create(:packages_tag, name: 'tag2', package: package) }
  let_it_be(:presenter) { described_class.new(package) }

  describe '#json_url' do
    let_it_be(:expected_suffix) { "/api/v4/projects/#{package.project_id}/packages/nuget/metadata/#{package.name}/#{package.version}.json" }

    subject { presenter.json_url }

    it { is_expected.to end_with(expected_suffix) }
  end

  describe '#archive_url' do
    let_it_be(:expected_suffix) { "/api/v4/projects/#{package.project_id}/packages/nuget/download/#{package.name}/#{package.version}/#{package.package_files.with_format('nupkg').last.file_name}" }

    subject { presenter.archive_url }

    it { is_expected.to end_with(expected_suffix) }
  end

  describe '#catalog_entry' do
    subject { presenter.catalog_entry }

    before do
      create_dependencies_for(package)
    end

    it 'returns an entry structure' do
      entry = subject

      expect(entry).to be_a Hash
      %i[json_url archive_url].each { |field| expect(entry[field]).not_to be_blank }
      %i[authors summary].each { |field| expect(entry[field]).to be_blank }
      expect(entry[:dependency_groups]).to eq expected_dependency_groups(package.project_id, package.name, package.version)
      expect(entry[:package_name]).to eq package.name
      expect(entry[:package_version]).to eq package.version
      expect(entry[:tags].split(::Packages::Tag::NUGET_TAGS_SEPARATOR)).to contain_exactly('tag1', 'tag2')

      %i[project_url license_url icon_url].each do |field|
        expect(entry.dig(:metadatum, field)).to eq(package.nuget_metadatum.send(field))
      end
    end
  end
end
