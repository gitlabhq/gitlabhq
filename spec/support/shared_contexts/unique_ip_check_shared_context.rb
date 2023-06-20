# frozen_string_literal: true

RSpec.shared_context 'unique ips sign in limit' do
  include StubENV
  let(:request_context) { Gitlab::RequestContext.instance }

  before do
    redis_cache_cleanup!
    redis_queues_cleanup!
    redis_shared_state_cleanup!
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    Gitlab::CurrentSettings.update!(
      unique_ips_limit_enabled: true,
      unique_ips_limit_time_window: 10000
    )

    # Make sure we're working with the same reqeust context everywhere
    allow(Gitlab::RequestContext).to receive(:instance).and_return(request_context)
  end

  def change_ip(ip)
    allow(request_context).to receive(:client_ip).and_return(ip)
  end

  def request_from_ip(ip)
    change_ip(ip)
    # Implement this method while including this shared context to simulate a request to GitLab
    # The method name gitlab_request was chosen over request to avoid conflict with rack request
    gitlab_request
    response
  end

  def operation_from_ip(ip)
    change_ip(ip)
    operation
  end
end
