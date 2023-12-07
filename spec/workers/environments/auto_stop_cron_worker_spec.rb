# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::AutoStopCronWorker, feature_category: :continuous_delivery do
  subject { worker.perform }

  let(:worker) { described_class.new }

  it 'executes Environments::AutoStopService' do
    expect_next_instance_of(Environments::AutoStopService) do |service|
      expect(service).to receive(:execute)
    end

    subject
  end
end
