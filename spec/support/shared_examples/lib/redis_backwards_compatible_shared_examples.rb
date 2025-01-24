# frozen_string_literal: true

RSpec.shared_examples_for 'using redis backwards compatible methods' do
  describe '.pop' do
    let(:table_name) { 'test_model' }
    let(:limit) { 3 }
    let(:redis) { instance_double(Redis) }
    let(:pipeline) { instance_double(Redis::PipelinedConnection) }
    let(:pipeline_result) { [nil, '{"id":1}', '{"id":2}'] }

    before do
      allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
      allow(redis).to receive(:pipelined).and_yield(pipeline).and_return(pipeline_result)
      allow(redis).to receive(:lpop)
    end

    # Ensure Redis 6.0 compatibility
    it 'uses pipelined lpop calls instead of lpop with limit' do
      expect(pipeline).to receive(:lpop).with(buffer_key).exactly(limit).times
      expect(redis).not_to receive(:lpop).with(buffer_key, limit)

      described_class.pop(table_name, limit)
    end
  end
end
