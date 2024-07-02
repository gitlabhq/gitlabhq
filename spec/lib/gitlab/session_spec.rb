# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Session do
  it 'uses the current thread as a data store' do
    Thread.current[:session_storage] = { a: :b }

    expect(described_class.current).to eq(a: :b)
  ensure
    Thread.current[:session_storage] = nil
  end

  describe '#with_session' do
    it 'sets session hash' do
      described_class.with_session(one: 1) do
        expect(described_class.current).to eq(one: 1)
      end
    end

    it 'restores current store after' do
      described_class.with_session(two: 2) {}

      expect(described_class.current).to eq nil
    end
  end

  describe '.session_id_for_worker' do
    context 'when session is ActionDispatch::Request::Session' do
      let(:rack_session) { Rack::Session::SessionId.new('6919a6f1bb119dd7396fadc38fd18d0d') }
      let(:session) do
        ActionDispatch::Request::Session.allocate.tap do |session|
          allow(session).to receive(:id).and_return(rack_session)
        end
      end

      it 'returns rack session private id' do
        described_class.with_session(session) do
          expect(described_class.session_id_for_worker).to eq(rack_session.private_id)
        end
      end
    end

    context 'when session behaves like Hash' do
      let(:session) { { set_session_id: 'abc' }.with_indifferent_access }

      it 'returns session id in Hash' do
        described_class.with_session(session) do
          expect(described_class.session_id_for_worker).to eq('abc')
        end
      end
    end

    context 'when sessionless' do
      let(:session) { nil }

      it 'returns nil' do
        described_class.with_session(session) do
          expect(described_class.session_id_for_worker).to eq(nil)
        end
      end
    end

    context 'when unknown type' do
      let(:session) { Object.new }

      it 'raises error' do
        described_class.with_session(session) do
          expect { described_class.session_id_for_worker }.to raise_error("Unsupported session class: Object")
        end
      end
    end
  end
end
