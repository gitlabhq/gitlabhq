# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::PackagesMetadataPresenter, feature_category: :package_registry do
  include_context 'with expected presenters dependency groups'

  let_it_be(:project) { create(:project) }
  let_it_be(:packages) { create_list(:nuget_package, 5, :with_metadatum, name: 'Dummy.Package', project: project) }

  let(:presenter) { described_class.new(::Packages::Nuget::Package.for_projects(project)) }

  describe '#count' do
    subject { presenter.count }

    it { is_expected.to eq 1 }
  end

  describe '#items' do
    let(:tag_names) { %w[tag1 tag2] }

    subject { presenter.items }

    before do
      packages.each do |pkg|
        tag_names.each { |tag| create(:packages_tag, package: pkg, name: tag) }

        create_dependencies_for(pkg)
      end
    end

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new do
        described_class.new(::Packages::Nuget::Package.for_projects(project)).items
      end

      create(:nuget_package, :with_metadatum, name: 'Dummy.Package', project: project)

      expect { described_class.new(::Packages::Nuget::Package.for_projects(project)).items }
        .not_to exceed_query_limit(control)
    end

    it 'returns an array' do
      items = subject

      expect(items).to be_a Array
      expect(items.size).to eq 1
    end

    it 'returns a summary structure' do
      item = subject.first

      expect(item).to be_a Hash
      %i[json_url lower_version upper_version].each { |field| expect(item[field]).not_to be_blank }
      expect(item[:packages_count]).to eq packages.count
      expect(item[:packages]).to be_a Array
      expect(item[:packages].size).to eq packages.count
    end

    it 'returns the catalog entries' do
      item = subject.first

      item[:packages].each do |pkg|
        expect(pkg).to be_a Hash
        %i[json_url archive_url catalog_entry].each { |field| expect(pkg[field]).not_to be_blank }
        catalog_entry = pkg[:catalog_entry]
        %i[json_url archive_url package_name package_version].each { |field| expect(catalog_entry[field]).not_to be_blank }
        %i[authors summary].each { |field| expect(catalog_entry[field]).to be_blank }
        expect(catalog_entry[:dependency_groups]).to eq(expected_dependency_groups(project.id, catalog_entry[:package_name], catalog_entry[:package_version]))
        expect(catalog_entry[:tags].split(::Packages::Tag::NUGET_TAGS_SEPARATOR)).to contain_exactly('tag1', 'tag2')

        %i[project_url license_url icon_url].each do |field|
          expect(catalog_entry.dig(:metadatum, field)).not_to be_blank
        end
      end
    end

    it 'returns sorted versions' do
      item = subject.first
      sorted_versions = presenter.send(:sort_versions, packages.map(&:version))

      expect(item[:lower_version]).to eq sorted_versions.first
      expect(item[:upper_version]).to eq sorted_versions.last
    end
  end
end
