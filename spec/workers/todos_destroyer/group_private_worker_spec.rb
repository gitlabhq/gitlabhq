# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::GroupPrivateWorker, feature_category: :team_planning do
  it "calls the Todos::Destroy::GroupPrivateService with the params it was given" do
    service = double

    expect(::Todos::Destroy::GroupPrivateService).to receive(:new).with(100).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(100)
  end
end
