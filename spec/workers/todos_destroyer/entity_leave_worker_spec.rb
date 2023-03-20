# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::EntityLeaveWorker, feature_category: :team_planning do
  it "calls the Todos::Destroy::EntityLeaveService with the params it was given" do
    service = double

    expect(::Todos::Destroy::EntityLeaveService).to receive(:new).with(100, 5, 'Group').and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(100, 5, 'Group')
  end
end
