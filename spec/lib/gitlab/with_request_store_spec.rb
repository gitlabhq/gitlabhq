# frozen_string_literal: true

require 'fast_spec_helper'
require 'request_store'

describe Gitlab::WithRequestStore do
  let(:fake_class) { Class.new { include Gitlab::WithRequestStore } }

  subject(:object) { fake_class.new }

  describe "#with_request_store" do
    it 'starts a request store and yields control' do
      expect(RequestStore).to receive(:begin!).ordered
      expect(RequestStore).to receive(:end!).ordered
      expect(RequestStore).to receive(:clear!).ordered

      expect { |b| object.with_request_store(&b) }.to yield_control
    end

    it 'only starts a request store once when nested' do
      expect(RequestStore).to receive(:begin!).ordered.once.and_call_original
      expect(RequestStore).to receive(:end!).ordered.once.and_call_original
      expect(RequestStore).to receive(:clear!).ordered.once.and_call_original

      object.with_request_store do
        expect { |b| object.with_request_store(&b) }.to yield_control
      end
    end
  end
end
