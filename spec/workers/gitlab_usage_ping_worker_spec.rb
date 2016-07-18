require 'spec_helper'

describe GitlabUsagePingWorker do
  subject { GitlabUsagePingWorker.new }

  it "gathers license data" do
    data = subject.data
    license = License.current

    expect(data[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
    expect(data[:version]).to eq(Gitlab::VERSION)
    expect(data[:licensee]).to eq(license.licensee)
    expect(data[:active_user_count]).to eq(User.active.count)
    expect(data[:licensee]).to eq(license.licensee)
    expect(data[:license_user_count]).to eq(license.user_count)
    expect(data[:license_starts_at]).to eq(license.starts_at)
    expect(data[:license_expires_at]).to eq(license.expires_at)
    expect(data[:license_add_ons]).to eq(license.add_ons)
    expect(data[:recorded_at]).to be_a(Time)
  end

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
