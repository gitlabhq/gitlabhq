# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::WrapsGitalyErrors, feature_category: :gitaly do
  subject(:wrapper) do
    klazz = Class.new { include Gitlab::Git::WrapsGitalyErrors }
    klazz.new
  end

  describe "#wrapped_gitaly_errors" do
    where(:original_error, :wrapped_error) do
      [
        [GRPC::NotFound, Gitlab::Git::Repository::NoRepository],
        [GRPC::InvalidArgument, ArgumentError],
        [GRPC::DeadlineExceeded, Gitlab::Git::CommandTimedOut],
        [GRPC::BadStatus, Gitlab::Git::CommandError]
      ]
    end

    with_them do
      it "wraps #{params[:original_error]} in a #{params[:wrapped_error]}" do
        expect { wrapper.wrapped_gitaly_errors { raise original_error, 'wrapped' } }
          .to raise_error(wrapped_error)
      end
    end

    context 'when wrap GRPC::ResourceExhausted' do
      context 'with Gitaly::LimitError detail' do
        let(:original_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::RESOURCE_EXHAUSTED,
            'resource exhausted',
            Gitaly::LimitError.new(
              error_message: "maximum time in concurrency queue reached",
              retry_after: Google::Protobuf::Duration.new(seconds: 5, nanos: 1500)
            )
          )
        end

        it "wraps in a Gitlab::Git::ResourceExhaustedError with error message" do
          expect { wrapper.wrapped_gitaly_errors { raise original_error } }.to raise_error do |wrapped_error|
            expect(wrapped_error).to be_a(Gitlab::Git::ResourceExhaustedError)
            expect(wrapped_error.message).to eql(
              "Upstream Gitaly has been exhausted: maximum time in concurrency queue reached. Try again later"
            )
            expect(wrapped_error.headers).to eql({ 'Retry-After' => 5 })
          end
        end
      end

      context 'with Gitaly::LimitError detail without retry after' do
        let(:original_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::RESOURCE_EXHAUSTED,
            'resource exhausted',
            Gitaly::LimitError.new(error_message: "maximum time in concurrency queue reached")
          )
        end

        it "wraps in a Gitlab::Git::ResourceExhaustedError with error message" do
          expect { wrapper.wrapped_gitaly_errors { raise original_error } }.to raise_error do |wrapped_error|
            expect(wrapped_error).to be_a(Gitlab::Git::ResourceExhaustedError)
            expect(wrapped_error.message).to eql(
              "Upstream Gitaly has been exhausted: maximum time in concurrency queue reached. Try again later"
            )
            expect(wrapped_error.headers).to eql({})
          end
        end
      end

      context 'without Gitaly::LimitError detail' do
        it("wraps in a Gitlab::Git::ResourceExhaustedError with default message") {
          expect { wrapper.wrapped_gitaly_errors { raise GRPC::ResourceExhausted } }.to raise_error do |wrapped_error|
            expect(wrapped_error).to be_a(Gitlab::Git::ResourceExhaustedError)
            expect(wrapped_error.message).to eql("Upstream Gitaly has been exhausted. Try again later")
            expect(wrapped_error.headers).to eql({})
          end
        }
      end
    end

    it 'does not swallow other errors' do
      expect { wrapper.wrapped_gitaly_errors { raise 'raised' } }
        .to raise_error(RuntimeError)
    end
  end
end
