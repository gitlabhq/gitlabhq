# frozen_string_literal: true

RSpec.shared_context 'workhorse headers' do
  # `iat` is required: `Gitlab::Workhorse.verify_api_request!` enforces
  # `iat_after: API_REQUEST_JWT_VALIDITY.ago`, so a no-iat token is rejected
  # with `JWT iat claim is missing`, which surfaces in request specs as a 403.
  let(:workhorse_token) do
    JWT.encode({ 'iss' => 'gitlab-workhorse', 'iat' => Time.now.to_i },
      Gitlab::Workhorse.secret, 'HS256')
  end

  let(:workhorse_headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
end
