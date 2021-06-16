# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveGitlabIssueTrackerServiceRecords do
  let(:services) { table(:services) }

  before do
    5.times { services.create!(type: 'GitlabIssueTrackerService') }
    services.create!(type: 'SomeOtherType')
  end

  it 'removes services records of type GitlabIssueTrackerService', :aggregate_failures do
    expect { migrate! }.to change { services.count }.from(6).to(1)
    expect(services.first.type).to eq('SomeOtherType')
    expect(services.where(type: 'GitlabIssueTrackerService')).to be_empty
  end
end
