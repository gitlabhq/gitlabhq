# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Nuget::SearchResult do
  let(:search_result) do
    {
      type: 'Package',
      authors: 'Author',
      name: 'PackageTest',
      version: '1.2.3',
      versions: [
        {
          json_url: 'http://sandbox.com/json/package',
          downloads: 100,
          version: '1.2.3'
        }
      ],
      summary: 'Summary',
      total_downloads: 100,
      verified: true,
      tags: 'tag1 tag2 tag3',
      metadatum: {
        project_url: 'http://sandbox.com/project',
        license_url: 'http://sandbox.com/license',
        icon_url: 'http://sandbox.com/icon'
      }
    }
  end

  let(:expected) do
    {
      '@type': 'Package',
      'authors': 'Author',
      'id': 'PackageTest',
      'title': 'PackageTest',
      'summary': 'Summary',
      'totalDownloads': 100,
      'verified': true,
      'version': '1.2.3',
      'tags': 'tag1 tag2 tag3',
      'projectUrl': 'http://sandbox.com/project',
      'licenseUrl': 'http://sandbox.com/license',
      'iconUrl': 'http://sandbox.com/icon',
      'versions': [
        {
          '@id': 'http://sandbox.com/json/package',
          'downloads': 100,
          'version': '1.2.3'
        }
      ]
    }
  end

  subject { described_class.new(search_result).as_json }

  it { is_expected.to eq(expected) }
end
