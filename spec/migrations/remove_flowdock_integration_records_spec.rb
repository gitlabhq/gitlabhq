# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db/post_migrate/20221129124240_remove_flowdock_integration_records.rb')

RSpec.describe RemoveFlowdockIntegrationRecords, feature_category: :integrations do
  let(:integrations) { table(:integrations) }

  before do
    integrations.create!(type_new: 'Integrations::Flowdock')
    integrations.create!(type_new: 'SomeOtherType')
  end

  it 'removes integrations records of type_new Integrations::Flowdock' do
    expect(integrations.count).to eq(2)

    migrate!

    expect(integrations.count).to eq(1)
    expect(integrations.first.type_new).to eq('SomeOtherType')
    expect(integrations.where(type_new: 'Integrations::Flowdock')).to be_empty
  end
end
