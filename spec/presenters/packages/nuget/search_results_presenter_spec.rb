# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SearchResultsPresenter, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_a) { create(:nuget_package, :with_metadatum, project: project, name: 'DummyPackageA') }
  let_it_be(:tag1) { create(:packages_tag, package: package_a, name: 'tag1') }
  let_it_be(:tag2) { create(:packages_tag, package: package_a, name: 'tag2') }
  let_it_be(:packages_b) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageB') }
  let_it_be(:packages_c) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageC') }

  let(:package_ids) { [package_a, *packages_b, *packages_c].map(&:id) }
  let(:packages) do
    ::Packages::Nuget::Package.for_projects(project).order(Arel.sql("POSITION(id::text IN '#{package_ids.join(',')}')"))
  end

  let(:search_results) do
    double(
      'search_results',
      total_count: 3,
      results: packages
    )
  end

  let(:presenter) { described_class.new(search_results) }

  describe '#total_count' do
    subject { presenter.total_count }

    it { is_expected.to eq 3 }
  end

  describe '#data' do
    subject(:data) { presenter.data }

    it 'returns the proper data structure' do
      expect(data.size).to eq 3
      pkg_a, pkg_b, pkg_c = data
      expect_package_result(pkg_a, package_a.name, [package_a.version], %w[tag1 tag2], with_metadatum: true)
      expect_package_result(pkg_b, packages_b.first.name, packages_b.map(&:version))
      expect_package_result(pkg_c, packages_c.first.name, packages_c.map(&:version))
    end

    it 'avoids n+1 database queries', :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { data }

      create_list(:nuget_package, 2, project: project, name: 'DummyPackageD')

      expect { described_class.new(search_results).data }.to issue_same_number_of_queries_as(control)
    end

    context 'when total_count is 0' do
      let(:search_results) { double('search_results', total_count: 0) }

      it { is_expected.to be_empty }
    end

    def expect_package_result(package_json, name, versions, tags = [], with_metadatum: false) # rubocop:disable Metrics/AbcSize
      expect(package_json[:type]).to eq 'Package'
      expect(package_json[:name]).to eq(name)
      expect(package_json[:total_downloads]).to eq 0
      expect(package_json[:verified]).to be_truthy
      expect(package_json[:version]).to eq presenter.send(:sort_versions, versions).last
      versions.zip(package_json[:versions]).each do |version, version_json|
        expect(version_json[:json_url]).to end_with("#{version}.json")
        expect(version_json[:downloads]).to eq 0
        expect(version_json[:version]).to eq version
      end

      if tags.any?
        expect(package_json[:tags].split(::Packages::Tag::NUGET_TAGS_SEPARATOR)).to contain_exactly(*tags)
      else
        expect(package_json[:tags]).to be_blank
      end

      %i[authors description project_url license_url icon_url].each do |field|
        expect(package_json.dig(:metadatum, field)).to with_metadatum ? be_present : be_blank
      end
    end
  end
end
