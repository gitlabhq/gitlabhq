# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Consistency do
  let(:session) do
    Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer)
  end

  before do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  describe '.with_read_consistency' do
    it 'sticks to primary database' do
      expect(session).not_to be_using_primary

      block = ->(&control) do
        described_class.with_read_consistency do
          expect(session).to be_using_primary

          control.call
        end
      end

      expect { |probe| block.call(&probe) }.to yield_control
    end
  end
end
