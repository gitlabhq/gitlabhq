# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Projects::Packages::Protection::Rule, feature_category: :package_registry do
  let(:package_protection_rule) { create(:package_protection_rule) }

  subject(:entity) { described_class.new(package_protection_rule).as_json }

  it 'exposes correct attributes' do
    expect(entity.keys).to match_array [
      :id,
      :project_id,
      :package_name_pattern,
      :package_type,
      :minimum_access_level_for_push
    ]
  end
end
