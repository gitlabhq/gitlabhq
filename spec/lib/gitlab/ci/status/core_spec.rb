# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Core do
  let(:subj) { double('subject', cache_key: 'foo') }

  subject(:status) do
    described_class.new(subj, double('user'))
  end

  describe '#cache_key' do
    it "uses the subject's cache key" do
      expect(status.cache_key).to eq(subj.cache_key)
    end
  end

  describe '#confirmation_message' do
    it 'returns nil by default' do
      expect(status.confirmation_message).to be_nil
    end
  end
end
