# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Instrumentation::Redis do
  def stub_storages(method, value)
    described_class::STORAGES.each do |storage|
      allow(storage).to receive(method) { value }
    end
  end

  shared_examples 'aggregation of redis storage data' do |method|
    describe "#{method} sum" do
      it "sums data from all Redis storages" do
        amount = 0.3

        stub_storages(method, amount)

        expect(described_class.public_send(method)).to eq(described_class::STORAGES.size * amount)
      end
    end
  end

  it_behaves_like 'aggregation of redis storage data', :get_request_count
  it_behaves_like 'aggregation of redis storage data', :query_time
  it_behaves_like 'aggregation of redis storage data', :read_bytes
  it_behaves_like 'aggregation of redis storage data', :write_bytes
end
