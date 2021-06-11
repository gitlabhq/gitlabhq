# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameSitemapNamespace do
  let(:namespaces) { table(:namespaces) }
  let(:routes) { table(:routes) }
  let(:sitemap_path) { 'sitemap' }

  it 'correctly run #up and #down' do
    create_namespace(sitemap_path)

    reversible_migration do |migration|
      migration.before -> {
        expect(namespaces.pluck(:path)).to contain_exactly(sitemap_path)
      }

      migration.after -> {
        expect(namespaces.pluck(:path)).to contain_exactly(sitemap_path + '0')
      }
    end
  end

  def create_namespace(path)
    namespaces.create!(name: path, path: path).tap do |namespace|
      routes.create!(path: namespace.path, name: namespace.name, source_id: namespace.id, source_type: 'Namespace')
    end
  end
end
