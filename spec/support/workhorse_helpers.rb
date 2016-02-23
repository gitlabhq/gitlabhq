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
        JSON.parse(Base64.urlsafe_decode64(header)),
      ]
    end
  end
end
