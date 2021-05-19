# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::WrapsGitalyErrors do
  subject(:wrapper) do
    klazz = Class.new { include Gitlab::Git::WrapsGitalyErrors }
    klazz.new
  end

  describe "#wrapped_gitaly_errors" do
    mapping = {
      GRPC::NotFound => Gitlab::Git::Repository::NoRepository,
      GRPC::InvalidArgument => ArgumentError,
      GRPC::BadStatus => Gitlab::Git::CommandError
    }

    mapping.each do |grpc_error, error|
      it "wraps #{grpc_error} in a #{error}" do
        expect { wrapper.wrapped_gitaly_errors { raise grpc_error, 'wrapped' } }
          .to raise_error(error)
      end
    end

    it 'does not swallow other errors' do
      expect { wrapper.wrapped_gitaly_errors { raise 'raised' } }
        .to raise_error(RuntimeError)
    end
  end
end
