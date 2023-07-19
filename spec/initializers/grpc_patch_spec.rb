# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GRPC monkey patch', feature_category: :shared do
  let(:server) { GRPC::RpcServer.new }
  let(:stub) do
    Class.new(Gitaly::CommitService::Service) do
      def find_all_commits(_request, _call)
        sleep 1

        nil
      end
    end
  end

  it 'raises DeadlineExceeded on a late server streaming response' do
    server_port = server.add_http2_port('0.0.0.0:0', :this_port_is_insecure)
    host = "localhost:#{server_port}"
    server.handle(stub)
    thr = Thread.new { server.run }

    stub = Gitaly::CommitService::Stub.new(host, :this_channel_is_insecure)
    request = Gitaly::FindAllCommitsRequest.new
    response = stub.find_all_commits(request, deadline: Time.now + 0.1)
    expect { response.to_a }.to raise_error(GRPC::DeadlineExceeded)

    server.stop
    thr.join
  end
end
