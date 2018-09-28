require 'spec_helper'

describe TodosDestroyer::ProjectPrivateWorker do
  it "calls the Todos::Destroy::ProjectPrivateService with the params it was given" do
    service = double

    expect(::Todos::Destroy::ProjectPrivateService).to receive(:new).with(100).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(100)
  end
end
