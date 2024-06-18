# frozen_string_literal: true

RSpec.shared_context 'JSON response' do
  # This should _not_ be a let block, otherwise it is memoized, and breaks the contract of
  # #response, which is to always return the response of the last request. Request specs
  # may do multiple requests in a single example, and making this a let would
  # cause stale responses to be returned.
  def json_response
    Gitlab::Json.parse(response.body)
  end
end
