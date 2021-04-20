# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::GrpcErrorProcessor do
  shared_examples 'processing an exception' do
    context 'when there is no GRPC exception' do
      let(:exception) { RuntimeError.new }
      let(:data) { { fingerprint: ['ArgumentError', 'Missing arguments'] } }

      it 'leaves data unchanged' do
        expect(result_hash).to include(data)
      end
    end

    context 'when there is a GPRC exception with a debug string' do
      let(:exception) { GRPC::DeadlineExceeded.new('Deadline Exceeded', {}, '{"hello":1}') }

      let(:data) do
        {
          extra: {
            caller: 'test'
          },
          fingerprint: [
            'GRPC::DeadlineExceeded',
            '4:Deadline Exceeded. debug_error_string:{"created":"@1598938192.005782000","description":"Error received from peer unix:/home/git/gitalypraefect.socket","file":"src/core/lib/surface/call.cc","file_line":1055,"grpc_message":"Deadline Exceeded","grpc_status":4}'
          ]
        }
      end

      it 'removes the debug error string and stores it as an extra field' do
        expect(result_hash[:fingerprint])
          .to eq(['GRPC::DeadlineExceeded', '4:Deadline Exceeded.'])

        expect(result_hash[:exception][:values].first)
          .to include(type: 'GRPC::DeadlineExceeded', value: '4:Deadline Exceeded.')

        expect(result_hash[:extra])
          .to include(caller: 'test', grpc_debug_error_string: '{"hello":1}')
      end

      context 'with no custom fingerprint' do
        let(:data) do
          { extra: { caller: 'test' } }
        end

        it 'removes the debug error string and stores it as an extra field' do
          expect(result_hash).not_to include(:fingerprint)

          expect(result_hash[:exception][:values].first)
            .to include(type: 'GRPC::DeadlineExceeded', value: '4:Deadline Exceeded.')

          expect(result_hash[:extra])
            .to include(caller: 'test', grpc_debug_error_string: '{"hello":1}')
        end
      end
    end
  end

  describe '.call' do
    let(:event) { Raven::Event.from_exception(exception, data) }
    let(:result_hash) { described_class.call(event).to_hash }

    it_behaves_like 'processing an exception'

    context 'when followed by #process' do
      let(:result_hash) { described_class.new.process(described_class.call(event).to_hash) }

      it_behaves_like 'processing an exception'
    end
  end

  describe '#process' do
    let(:event) { Raven::Event.from_exception(exception, data) }
    let(:result_hash) { described_class.new.process(event.to_hash) }

    context 'with sentry_processors_before_send disabled' do
      before do
        stub_feature_flags(sentry_processors_before_send: false)
      end

      it_behaves_like 'processing an exception'
    end
  end
end
