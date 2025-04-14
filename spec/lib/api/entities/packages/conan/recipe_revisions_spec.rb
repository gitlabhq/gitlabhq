# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Packages::Conan::RecipeRevisions, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:revision1) { package.conan_recipe_revisions.first }
  let_it_be(:revision2) { create(:conan_recipe_revision, package: package) }

  let(:entity) { described_class.new(package) }

  describe '#as_json' do
    subject(:json) { entity.as_json }

    it 'exposes the reference and revisions', :aggregate_failures do
      expect(json[:reference]).to eq(package.conan_recipe)
      expect(json[:revisions].map(&:as_json)).to eq([
        { 'revision' => revision2.revision, 'time' => revision2.created_at.iso8601(3) },
        { 'revision' => revision1.revision, 'time' => revision1.created_at.iso8601(3) }
      ])
    end

    context 'when the limit is reached' do
      before do
        stub_const("#{described_class}::MAX_REVISIONS_COUNT", 1)
      end

      it 'limits the number of revisions to MAX_REVISIONS_COUNT' do
        expect(json[:revisions].map(&:as_json)).to eq([
          'revision' => revision2.revision, 'time' => revision2.created_at.iso8601(3)
        ])
      end
    end
  end
end
