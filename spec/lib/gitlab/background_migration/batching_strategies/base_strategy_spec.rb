# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BaseStrategy, '#next_batch' do
  let(:connection) { double(:connection) }
  let(:base_strategy_class) { Class.new(described_class) }
  let(:base_strategy) { base_strategy_class.new(connection: connection) }

  describe '#next_batch' do
    it 'raises an error if not overridden by a subclass' do
      expect { base_strategy.next_batch }.to raise_error(NotImplementedError, /does not implement next_batch/)
    end
  end
end
