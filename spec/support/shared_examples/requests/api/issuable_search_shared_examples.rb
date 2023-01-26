# frozen_string_literal: true

RSpec.shared_examples 'issuable API rate-limited search' do
  it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
    let(:current_user) { user }

    def request
      get api(url, current_user), params: { scope: 'all', search: issuable.title }
    end
  end

  it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated do
    def request
      get api(url), params: { scope: 'all', search: issuable.title }
    end
  end
end
