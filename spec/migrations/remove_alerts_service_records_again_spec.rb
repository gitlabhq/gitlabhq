# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210205214003_remove_alerts_service_records_again.rb')

RSpec.describe RemoveAlertsServiceRecordsAgain do
  let(:services) { table(:services) }

  before do
    5.times { services.create!(type: 'AlertsService') }
    services.create!(type: 'SomeOtherType')
  end

  it 'removes services records of type AlertsService and corresponding data', :aggregate_failures do
    expect(services.count).to eq(6)

    migrate!

    expect(services.count).to eq(1)
    expect(services.first.type).to eq('SomeOtherType')
    expect(services.where(type: 'AlertsService')).to be_empty
  end
end
