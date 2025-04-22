# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Packages::Conan::Revision, feature_category: :package_registry do
  shared_examples 'exposes revision attributes' do |factory|
    let(:revision) { build_stubbed(factory) }
    let(:entity) { described_class.new(revision) }

    subject { entity.as_json }

    it 'exposes required attributes' do
      is_expected.to eq(
        revision: revision.revision,
        time: revision.created_at
      )
    end
  end

  it_behaves_like 'exposes revision attributes', :conan_recipe_revision
  it_behaves_like 'exposes revision attributes', :conan_package_revision
end
