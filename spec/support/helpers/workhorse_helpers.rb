module WorkhorseHelpers
  extend self

  def workhorse_send_data
    @_workhorse_send_data ||= begin
      header = response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]
      split_header = header.split(':')
      type = split_header.shift
      header = split_header.join(':')
      [
        type,
        JSON.parse(Base64.urlsafe_decode64(header))
      ]
    end
  end

  def workhorse_internal_api_request_header
    jwt_token = JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256')
    { 'HTTP_' + Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER.upcase.tr('-', '_') => jwt_token }
  end
end
