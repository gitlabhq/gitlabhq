# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IpAddress Rack middleware', feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let(:token) { create(:personal_access_token, user: user, scopes: %w[api], last_used_at: nil) }

  # Sessionless auth for feeds runs from a prepend_before_action, ahead of
  # ApplicationController's around_action that used to be the only thing setting
  # the IP, so the token's last-used IP was never recorded on these paths.
  it 'sets the IP before a feed request resolves its token' do
    get '/dashboard/work_items.atom',
      params: { private_token: token.token, author_id: user.id },
      headers: { 'REMOTE_ADDR' => '192.168.7.7' }

    expect(response).to have_gitlab_http_status(:ok)
    expect(token.reload.last_used_ips.map { |ip| ip.ip_address.to_s }).to contain_exactly('192.168.7.7')
  end
end
