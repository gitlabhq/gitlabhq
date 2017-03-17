require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ActiveRecordProxy do
  describe '#inherited' do
    it 'adds the ModelProxy module to the singleton class' do
      base = Class.new do
        include Gitlab::Database::LoadBalancing::ActiveRecordProxy
      end

      model = Class.new(base)

      expect(model.included_modules).to include(described_class)
    end
  end
end
