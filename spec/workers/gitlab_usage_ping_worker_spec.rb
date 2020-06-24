# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabUsagePingWorker do
  subject { described_class.new }

  it 'delegates to SubmitUsagePingService' do
    allow(subject).to receive(:try_obtain_lease).and_return(true)

    expect_next_instance_of(SubmitUsagePingService) do |instance|
      expect(instance).to receive(:execute)
    end

    subject.perform
  end
end
