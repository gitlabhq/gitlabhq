# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateIntegrationsTriggerTypeNewOnInsertNullSafe, :migration, feature_category: :integrations do
  let(:integrations) { table(:integrations) }

  before do
    migrate!
  end

  it 'leaves defined values alone' do
    record = integrations.create!(type: 'XService', type_new: 'Integrations::Y')

    expect(integrations.find(record.id)).to have_attributes(type: 'XService', type_new: 'Integrations::Y')
  end

  it 'keeps type_new synchronized with type' do
    record = integrations.create!(type: 'AbcService', type_new: nil)

    expect(integrations.find(record.id)).to have_attributes(
      type: 'AbcService',
      type_new: 'Integrations::Abc'
    )
  end

  it 'keeps type synchronized with type_new' do
    record = integrations.create!(type: nil, type_new: 'Integrations::Abc')

    expect(integrations.find(record.id)).to have_attributes(
      type: 'AbcService',
      type_new: 'Integrations::Abc'
    )
  end
end
