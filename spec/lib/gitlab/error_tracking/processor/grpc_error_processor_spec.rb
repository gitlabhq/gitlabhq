# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::GrpcErrorProcessor do
  describe '#process' do
    subject { described_class.new }

    context 'when there is no GRPC exception' do
      let(:data) { { fingerprint: ['ArgumentError', 'Missing arguments'] } }

      it 'leaves data unchanged' do
        expect(subject.process(data)).to eq(data)
      end
    end

    context 'when there is a GPRC exception with a debug string' do
      let(:data) do
        {
          exception: {
            values: [
              {
                type: "GRPC::DeadlineExceeded",
                value: "4:DeadlineExceeded. debug_error_string:{\"hello\":1}"
              }
            ]
          },
          extra: {
            caller: 'test'
          },
          fingerprint: [
            "GRPC::DeadlineExceeded",
            "4:Deadline Exceeded. debug_error_string:{\"created\":\"@1598938192.005782000\",\"description\":\"Error received from peer unix:/home/git/gitalypraefect.socket\",\"file\":\"src/core/lib/surface/call.cc\",\"file_line\":1055,\"grpc_message\":\"Deadline Exceeded\",\"grpc_status\":4}"
          ]
        }
      end

      let(:expected) do
        {
          fingerprint: [
            "GRPC::DeadlineExceeded",
            "4:Deadline Exceeded."
          ],
          exception: {
            values: [
              {
                type: "GRPC::DeadlineExceeded",
                value: "4:DeadlineExceeded."
              }
            ]
          },
          extra: {
            caller: 'test',
            grpc_debug_error_string: "{\"hello\":1}"
         }
        }
      end

      it 'removes the debug error string and stores it as an extra field' do
        expect(subject.process(data)).to eq(expected)
      end

      context 'with no custom fingerprint' do
        before do
          data.delete(:fingerprint)
          expected.delete(:fingerprint)
        end

        it 'removes the debug error string and stores it as an extra field' do
          expect(subject.process(data)).to eq(expected)
        end
      end
    end
  end
end
