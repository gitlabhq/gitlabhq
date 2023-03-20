# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::DestroyedDesignsWorker, feature_category: :team_planning do
  let(:service) { double }

  it 'calls the Todos::Destroy::DesignService with design_ids parameter' do
    expect(::Todos::Destroy::DesignService).to receive(:new).with([1, 5]).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform([1, 5])
  end
end
