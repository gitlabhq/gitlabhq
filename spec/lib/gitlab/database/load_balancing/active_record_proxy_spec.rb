require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ActiveRecordProxy do
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
  end
end
