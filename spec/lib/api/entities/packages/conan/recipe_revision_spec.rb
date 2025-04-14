# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Packages::Conan::RecipeRevision, feature_category: :package_registry do
  let(:recipe_revision) { build_stubbed(:conan_recipe_revision) }
  let(:entity) { described_class.new(recipe_revision) }

  subject { entity.as_json }

  it 'exposes required attributes' do
    is_expected.to eq(
      revision: recipe_revision.revision,
      time: recipe_revision.created_at
    )
  end
end
