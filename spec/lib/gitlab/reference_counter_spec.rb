# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ReferenceCounter, :clean_gitlab_redis_shared_state do
  let(:reference_counter) { described_class.new('project-1') }

  describe '#increase' do
    it 'increases and sets the expire time of a reference count for a path' do
      expect { reference_counter.increase }.to change { reference_counter.value }.by(1)
      expect(reference_counter.expires_in).to be_positive
      expect(reference_counter.increase).to be(true)
    end
  end

  describe '#decrease' do
    it 'decreases the reference count for a path' do
      reference_counter.increase

      expect { reference_counter.decrease }.to change { reference_counter.value }.by(-1)
    end

    it 'warns if attempting to decrease a counter with a value of zero or less, and resets the counter' do
      expect(Gitlab::AppLogger).to receive(:warn).with("Reference counter for project-1 " \
        "decreased when its value was less than 1. Resetting the counter.")
      expect { reference_counter.decrease }.not_to change { reference_counter.value }
    end
  end

  describe '#value' do
    it 'get the reference count for a path' do
      expect(reference_counter.value).to eq(0)

      reference_counter.increase

      expect(reference_counter.value).to eq(1)
    end
  end

  describe '#reset!' do
    it 'resets reference count down to zero' do
      3.times { reference_counter.increase }

      expect { reference_counter.reset! }.to change { reference_counter.value }.from(3).to(0)
    end
  end

  describe '#expires_in' do
    it 'displays the expiration time in seconds' do
      reference_counter.increase

      expect(reference_counter.expires_in).to be_between(500, 600)
    end
  end
end
