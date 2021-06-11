# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameSitemapRootNamespaces do
  let(:namespaces) { table(:namespaces) }
  let(:routes) { table(:routes) }
  let(:sitemap_path) { 'sitemap.xml' }
  let(:sitemap_gz_path) { 'sitemap.xml.gz' }
  let(:other_path1) { 'sitemap.xmlfoo' }
  let(:other_path2) { 'foositemap.xml' }

  it 'correctly run #up and #down' do
    create_namespace(sitemap_path)
    create_namespace(sitemap_gz_path)
    create_namespace(other_path1)
    create_namespace(other_path2)

    reversible_migration do |migration|
      migration.before -> {
        expect(namespaces.pluck(:path)).to contain_exactly(sitemap_path, sitemap_gz_path, other_path1, other_path2)
      }

      migration.after -> {
        expect(namespaces.pluck(:path)).to contain_exactly(sitemap_path + '0', sitemap_gz_path + '0', other_path1, other_path2)
      }
    end
  end

  def create_namespace(path)
    namespaces.create!(name: path, path: path).tap do |namespace|
      routes.create!(path: namespace.path, name: namespace.name, source_id: namespace.id, source_type: 'Namespace')
    end
  end
end
