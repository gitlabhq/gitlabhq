# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::GrpcErrorProcessor, :sentry, feature_category: :integrations do
  describe '.call' do
    let(:sentry_event) do
      Sentry.get_current_client.event_from_exception(exception)
    end

    let(:result_hash) { described_class.call(event).to_hash }

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

    before do
      Sentry.get_current_scope.update_from_options(**data)
      Sentry.get_current_scope.apply_to_event(sentry_event)
    end

    after do
      Sentry.get_current_scope.clear
    end

    context 'when there is no GRPC exception' do
      let(:exception) { RuntimeError.new }
      let(:data) { { fingerprint: ['ArgumentError', 'Missing arguments'] } }

      shared_examples 'leaves data unchanged' do
        it { expect(result_hash).to include(data) }
      end

      context 'with Sentry event' do
        let(:event) { sentry_event }

        it_behaves_like 'leaves data unchanged'
      end
    end

    context 'when there is a GRPC exception with a debug string' do
      let(:exception) { GRPC::DeadlineExceeded.new('Deadline Exceeded', {}, '{"hello":1}') }

      shared_examples 'processes the exception' do
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
            expect(result_hash[:fingerprint]).to be_blank

            expect(result_hash[:exception][:values].first)
              .to include(type: 'GRPC::DeadlineExceeded', value: '4:Deadline Exceeded.')

            expect(result_hash[:extra])
              .to include(caller: 'test', grpc_debug_error_string: '{"hello":1}')
          end
        end
      end

      context 'with Sentry event' do
        let(:event) { sentry_event }

        it_behaves_like 'processes the exception'
      end
    end

    context 'when there is a wrapped GRPC exception with a debug string' do
      let(:inner_exception) do
        GRPC::DeadlineExceeded.new('Deadline Exceeded', {}, '{"hello":1}')
      end

      let(:exception) do
        begin
          raise inner_exception
        rescue GRPC::DeadlineExceeded
          raise StandardError.new, inner_exception.message
        end
      rescue StandardError => e
        e
      end

      shared_examples 'processes the exception' do
        it 'removes the debug error string and stores it as an extra field' do
          expect(result_hash[:fingerprint])
            .to eq(['GRPC::DeadlineExceeded', '4:Deadline Exceeded.'])

          expect(result_hash[:exception][:values].first)
            .to include(type: 'GRPC::DeadlineExceeded', value: '4:Deadline Exceeded.')

          expect(result_hash[:exception][:values].second)
            .to include(type: 'StandardError', value: '4:Deadline Exceeded.')

          expect(result_hash[:extra])
            .to include(caller: 'test', grpc_debug_error_string: '{"hello":1}')
        end

        context 'with no custom fingerprint' do
          let(:data) do
            { extra: { caller: 'test' } }
          end

          it 'removes the debug error string and stores it as an extra field' do
            expect(result_hash[:fingerprint]).to be_blank

            expect(result_hash[:exception][:values].first)
              .to include(type: 'GRPC::DeadlineExceeded', value: '4:Deadline Exceeded.')

            expect(result_hash[:exception][:values].second)
              .to include(type: 'StandardError', value: '4:Deadline Exceeded.')

            expect(result_hash[:extra])
              .to include(caller: 'test', grpc_debug_error_string: '{"hello":1}')
          end
        end
      end

      context 'with Sentry event' do
        let(:event) { sentry_event }

        it_behaves_like 'processes the exception'
      end
    end
  end
end
