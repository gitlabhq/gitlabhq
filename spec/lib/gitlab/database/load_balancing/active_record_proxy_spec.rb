# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ActiveRecordProxy do
  describe '#connection' do
    it 'returns a connection proxy' do
      dummy = Class.new do
        include Gitlab::Database::LoadBalancing::ActiveRecordProxy
      end

      proxy = double(:proxy)

      expect(Gitlab::Database::LoadBalancing).to receive(:proxy)
        .and_return(proxy)

      expect(dummy.new.connection).to eq(proxy)
    end

    it 'returns a connection when no proxy is present' do
      allow(Gitlab::Database::LoadBalancing).to receive(:proxy).and_return(nil)

      expect(ActiveRecord::Base.connection)
        .to eq(ActiveRecord::Base.retrieve_connection)
    end
  end
end
