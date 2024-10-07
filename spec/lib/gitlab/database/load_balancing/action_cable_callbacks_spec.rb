# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ActionCableCallbacks, :request_store, feature_category: :shared do
  describe '.wrapper' do
    it 'releases the connection and clears the session' do
      expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts)
      expect(Gitlab::Database::LoadBalancing::SessionMap).to receive(:clear_session)

      described_class.wrapper.call(nil, -> {})
    end

    context 'with an exception' do
      it 'releases the connection and clears the session' do
        expect(Gitlab::Database::LoadBalancing).to receive(:release_hosts)
        expect(Gitlab::Database::LoadBalancing::SessionMap).to receive(:clear_session)

        expect do
          described_class.wrapper.call(nil, -> { raise 'test_exception' })
        end.to raise_error('test_exception')
      end
    end
  end
end
