# frozen_string_literal: true

RSpec.shared_context 'with a server running the dependency proxy' do
  def run_server(handler)
    default_server = Capybara.server

    Capybara.server = Capybara.servers[:puma]
    server = Capybara::Server.new(handler)
    server.boot
    server
  ensure
    Capybara.server = default_server
  end
end
