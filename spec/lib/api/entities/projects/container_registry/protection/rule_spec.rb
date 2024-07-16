# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Projects::ContainerRegistry::Protection::Rule, feature_category: :container_registry do
  let(:container_registry_protection_rule) { create(:container_registry_protection_rule) }

  subject(:entity) { described_class.new(container_registry_protection_rule).as_json }

  it 'exposes correct attributes' do
    expect(entity.keys).to match_array [
      :id,
      :project_id,
      :repository_path_pattern,
      :minimum_access_level_for_push,
      :minimum_access_level_for_delete
    ]
  end
end
