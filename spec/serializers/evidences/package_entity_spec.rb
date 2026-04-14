# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::PackageEntity, feature_category: :release_evidence do
  let(:entity) { described_class.new(build(:generic_package)) }

  subject(:package_json) { entity.as_json }

  it 'exposes the expected fields' do
    expect(package_json.keys).to contain_exactly(:id, :name, :version, :package_type, :created_at)
  end
end
