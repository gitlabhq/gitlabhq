# frozen_string_literal: true

RSpec.shared_context 'file upload requests helpers' do
  def capybara_url(path)
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}#{path}"
  end
end
