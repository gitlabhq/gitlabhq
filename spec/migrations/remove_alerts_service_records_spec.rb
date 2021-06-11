# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveAlertsServiceRecords do
  let(:services) { table(:services) }
  let(:alerts_service_data) { table(:alerts_service_data) }

  before do
    5.times do
      service = services.create!(type: 'AlertsService')
      alerts_service_data.create!(service_id: service.id)
    end

    services.create!(type: 'SomeOtherType')
  end

  it 'removes services records of type AlertsService and corresponding data', :aggregate_failures do
    expect(services.count).to eq(6)
    expect(alerts_service_data.count).to eq(5)

    migrate!

    expect(services.count).to eq(1)
    expect(services.first.type).to eq('SomeOtherType')
    expect(services.where(type: 'AlertsService')).to be_empty
    expect(alerts_service_data.all).to be_empty
  end
end
