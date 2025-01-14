# frozen_string_literal: true

RSpec.shared_examples "multi_store_wrapper_shared_examples" do
  let(:config_file_name) { instance_specific_config_file }
  let_it_be(:pool_name) { "#{described_class.store_name.underscore}_multi_store" }

  before do
    allow(described_class).to receive(:config_file_name).and_return(Rails.root.join(config_file_name).to_s)
    allow(described_class).to receive(:redis_yml_path).and_return('/dev/null')

    clear_multistore_pool
  end

  after do
    clear_multistore_pool
  end

  describe '.with' do
    it 'yields a MultiStore' do
      described_class.with do |conn|
        expect(conn).to be_instance_of(Gitlab::Redis::MultiStore)
      end
    end

    context 'when running on single-threaded runtime' do
      before do
        allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(false)
      end

      it 'instantiates a connection pool with size 5' do
        expect(ConnectionPool).to receive(:new).with(size: 5, name: pool_name).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end

    context 'when running on multi-threaded runtime' do
      before do
        allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(true)
        allow(Gitlab::Runtime).to receive(:max_threads).and_return(18)
      end

      it 'instantiates a connection pool with a size based on the concurrency of the worker' do
        expect(ConnectionPool).to receive(:new).with(size: 18 + 5, name: pool_name).and_call_original

        described_class.with { |_redis_shared_example| true }
      end
    end

    context 'when there is no config at all' do
      before do
        # Undo top-level stub of config_file_name because we are testing that method now.
        allow(described_class).to receive(:config_file_name).and_call_original
        allow(described_class).to receive(:rails_root).and_return(rails_root)
      end

      it 'can run an empty block' do
        expect { described_class.with { nil } }.not_to raise_error
      end
    end
  end

  def clear_multistore_pool
    described_class.remove_instance_variable(:@multistore_pool)
  rescue NameError
    # raised if @pool was not set; ignore
  end
end
