# frozen_string_literal: true

require_relative "helper"
require "sidekiq/sd_notify"
require "sidekiq/systemd"

describe "Systemd" do
  before do
    ::Dir::Tmpname.create("sidekiq_socket") do |sockaddr|
      @sockaddr = sockaddr
      @socket = Socket.new(:UNIX, :DGRAM, 0)
      socket_ai = Addrinfo.unix(sockaddr)
      @socket.bind(socket_ai)
      ENV["NOTIFY_SOCKET"] = sockaddr
    end
  end

  after do
    @socket&.close
    File.unlink(@sockaddr) if @sockaddr
    @socket = nil
    @sockaddr = nil
  end

  def socket_message
    @socket.recvfrom(10)[0]
  end

  it "notifies" do
    count = Sidekiq::SdNotify.ready
    assert_equal(socket_message, "READY=1")
    assert_equal(ENV["NOTIFY_SOCKET"], @sockaddr)
    assert_equal(count, 7)

    count = Sidekiq::SdNotify.stopping
    assert_equal(socket_message, "STOPPING=1")
    assert_equal(ENV["NOTIFY_SOCKET"], @sockaddr)
    assert_equal(count, 10)

    refute Sidekiq::SdNotify.watchdog?
  end
end
