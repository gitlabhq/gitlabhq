# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Git::BaseError do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(message).to_s }

  where(:message, :result) do
    "GRPC::DeadlineExceeded: 4:DeadlineExceeded. debug_error_string:{\"hello\":1}" | "GRPC::DeadlineExceeded: 4:DeadlineExceeded."
    "GRPC::DeadlineExceeded: 4:DeadlineExceeded." | "GRPC::DeadlineExceeded: 4:DeadlineExceeded."
    "GRPC::DeadlineExceeded: 4:DeadlineExceeded. debug_error_string:{\"created\":\"@1598978902.544524530\",\"description\":\"Error received from peer ipv4: debug_error_string:test\"}" | "GRPC::DeadlineExceeded: 4:DeadlineExceeded."
    "9:Multiple lines\nTest line. debug_error_string:{\"created\":\"@1599074877.106467000\"}" | "9:Multiple lines\nTest line."
    "other message" | "other message"
    nil | "Gitlab::Git::BaseError"
  end

  with_them do
    it { is_expected.to eq(result) }
  end

  describe "When initialized with GRPC errors" do
    let(:grpc_error) { GRPC::DeadlineExceeded.new }
    let(:git_error) { described_class.new grpc_error }

    it "has status and code fields" do
      expect(git_error.service).to eq('git')
      expect(git_error.status).to eq(4)
      expect(git_error.code).to eq('deadline_exceeded')
    end
  end
end
