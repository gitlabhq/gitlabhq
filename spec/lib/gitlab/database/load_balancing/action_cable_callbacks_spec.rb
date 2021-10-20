# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ActionCableCallbacks, :request_store do
  describe '.wrapper' do
    it 'uses primary and then releases the connection and clears the session' do
      expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts)
      expect(Gitlab::Database::LoadBalancing::Session).to receive(:clear_session)

      described_class.wrapper.call(
        nil,
        lambda do
          expect(Gitlab::Database::LoadBalancing::Session.current.use_primary?).to eq(true)
        end
      )
    end

    context 'with an exception' do
      it 'releases the connection and clears the session' do
        expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts)
        expect(Gitlab::Database::LoadBalancing::Session).to receive(:clear_session)

        expect do
          described_class.wrapper.call(nil, lambda { raise 'test_exception' })
        end.to raise_error('test_exception')
      end
    end
  end
end
