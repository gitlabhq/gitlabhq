# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GrapeLogging::Loggers::ExceptionLogger do
  subject { described_class.new }

  let(:mock_request) { OpenStruct.new(env: {}) }

  describe ".parameters" do
    describe 'when no exception is available' do
      it 'returns an empty hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'when an exception is available' do
      let(:exception) { RuntimeError.new('This is a test') }
      let(:mock_request) do
        OpenStruct.new(
          env: {
            ::API::Helpers::API_EXCEPTION_ENV => exception
          }
        )
      end

      let(:expected) do
        {
          'exception.class' => 'RuntimeError',
          'exception.message' => 'This is a test'
        }
      end

      it 'returns the correct fields' do
        expect(subject.parameters(mock_request, nil)).to eq(expected)
      end

      context 'with backtrace' do
        before do
          current_backtrace = caller
          allow(exception).to receive(:backtrace).and_return(current_backtrace)
          expected['exception.backtrace'] = Gitlab::Profiler.clean_backtrace(current_backtrace)
        end

        it 'includes the backtrace' do
          expect(subject.parameters(mock_request, nil)).to eq(expected)
        end
      end
    end
  end
end
