# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::TcpChecker, :permit_dns do
  before do
    @server = TCPServer.new('localhost', 0)
    _, @port, _, @ip = @server.addr
  end

  after do
    @server.close
  end

  subject(:checker) { described_class.new(@ip, @port) }

  describe '#check' do
    subject { checker.check }

    it 'can connect to an open port' do
      is_expected.to be_truthy

      expect(checker.error).to be_nil
    end

    it 'fails to connect to a closed port' do
      @server.close

      is_expected.to be_falsy

      expect(checker.error).to be_a(Errno::ECONNREFUSED)
    end
  end
end
