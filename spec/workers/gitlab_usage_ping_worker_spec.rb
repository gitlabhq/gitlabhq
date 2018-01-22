require 'spec_helper'

describe GitlabUsagePingWorker do
  subject { described_class.new }

  it 'delegates to SubmitUsagePingService' do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)

    expect_any_instance_of(SubmitUsagePingService).to receive(:execute)

    subject.perform
  end
end
