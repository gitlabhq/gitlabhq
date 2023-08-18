# frozen_string_literal: true

RSpec.shared_examples 'admin_runners_data_attributes contains data' do
  it 'returns data' do
    expect(subject).to include(
      runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
      registration_token: Gitlab::CurrentSettings.runners_registration_token,
      online_contact_timeout_secs: 7200,
      stale_timeout_secs: 7889238
    )
  end
end
