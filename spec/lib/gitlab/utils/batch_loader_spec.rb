# frozen_string_literal: true

require 'fast_spec_helper'
require 'batch-loader'

RSpec.describe Gitlab::Utils::BatchLoader do
  let(:stubbed_loader) do
    double( # rubocop:disable RSpec/VerifiedDoubles
      'Loader',
      load_lazy_method: [],
      load_lazy_method_same_batch_key: [],
      load_lazy_method_other_batch_key: []
    )
  end

  let(:test_module) do
    Module.new do
      def self.lazy_method(id)
        BatchLoader.for(id).batch(key: :my_batch_name) do |ids, loader|
          stubbed_loader.load_lazy_method(ids)

          ids.each { |id| loader.call(id, id) }
        end
      end

      def self.lazy_method_same_batch_key(id)
        BatchLoader.for(id).batch(key: :my_batch_name) do |ids, loader|
          stubbed_loader.load_lazy_method_same_batch_key(ids)

          ids.each { |id| loader.call(id, id) }
        end
      end

      def self.lazy_method_other_batch_key(id)
        BatchLoader.for(id).batch(key: :other_batch_name) do |ids, loader|
          stubbed_loader.load_lazy_method_other_batch_key(ids)

          ids.each { |id| loader.call(id, id) }
        end
      end
    end
  end

  before do
    BatchLoader::Executor.clear_current
    allow(test_module).to receive(:stubbed_loader).and_return(stubbed_loader)
  end

  describe '.clear_key' do
    it 'clears batched items which match the specified batch key' do
      test_module.lazy_method(1)
      test_module.lazy_method_same_batch_key(2)
      test_module.lazy_method_other_batch_key(3)

      described_class.clear_key(:my_batch_name)

      test_module.lazy_method(4).to_i
      test_module.lazy_method_same_batch_key(5).to_i
      test_module.lazy_method_other_batch_key(6).to_i

      expect(stubbed_loader).to have_received(:load_lazy_method).with([4])
      expect(stubbed_loader).to have_received(:load_lazy_method_same_batch_key).with([5])
      expect(stubbed_loader).to have_received(:load_lazy_method_other_batch_key).with([3, 6])
    end

    it 'clears loaded values which match the specified batch key' do
      test_module.lazy_method(1).to_i
      test_module.lazy_method_same_batch_key(2).to_i
      test_module.lazy_method_other_batch_key(3).to_i

      described_class.clear_key(:my_batch_name)

      test_module.lazy_method(1).to_i
      test_module.lazy_method_same_batch_key(2).to_i
      test_module.lazy_method_other_batch_key(3).to_i

      expect(stubbed_loader).to have_received(:load_lazy_method).with([1]).twice
      expect(stubbed_loader).to have_received(:load_lazy_method_same_batch_key).with([2]).twice
      expect(stubbed_loader).to have_received(:load_lazy_method_other_batch_key).with([3])
    end
  end
end
