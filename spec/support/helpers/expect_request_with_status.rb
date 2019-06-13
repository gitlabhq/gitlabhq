# frozen_string_literal: true

module ExpectRequestWithStatus
  def expect_request_with_status(status)
    expect do
      yield

      expect(response).to have_gitlab_http_status(status)
    end
  end
end
