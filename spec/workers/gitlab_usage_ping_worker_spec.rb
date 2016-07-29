require 'spec_helper'

describe GitlabUsagePingWorker do
  subject { GitlabUsagePingWorker.new }

  it "sends POST request" do
    stub_application_setting(usage_ping_enabled: true)

    stub_request(:post, "https://version.gitlab.com/usage_data").
        to_return(status: 200, body: '', headers: {})
    expect(subject).to receive(:try_obtain_lease).and_return(true)

    expect(subject.perform.response.code.to_i).to eq(200)
  end

  it "does not run if usage ping is disabled" do
    stub_application_setting(usage_ping_enabled: false)

    expect(subject).not_to receive(:try_obtain_lease)
    expect(subject).not_to receive(:perform)
  end
end
