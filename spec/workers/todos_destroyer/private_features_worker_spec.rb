# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::PrivateFeaturesWorker do
  it "calls the Todos::Destroy::PrivateFeaturesService with the params it was given" do
    service = double

    expect(::Todos::Destroy::PrivateFeaturesService).to receive(:new).with(100, nil).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(100)
  end
end
