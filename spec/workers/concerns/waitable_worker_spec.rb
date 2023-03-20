# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WaitableWorker, feature_category: :shared do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      cattr_accessor(:counter) { 0 }

      include ApplicationWorker
      prepend WaitableWorker

      def perform(count = 0)
        self.class.counter += count
      end
    end
  end

  subject(:job) { worker.new }

  describe '#perform' do
    shared_examples 'perform' do
      it 'notifies the JobWaiter when done if the key is provided' do
        key = Gitlab::JobWaiter.new.key
        expect(Gitlab::JobWaiter).to receive(:notify).with(key, job.jid)

        job.perform(*args, key)
      end

      it 'does not notify the JobWaiter when done if no key is provided' do
        expect(Gitlab::JobWaiter).not_to receive(:notify)

        job.perform(*args)
      end
    end

    context 'when the worker takes arguments' do
      let(:args) { [1] }

      it_behaves_like 'perform'
    end

    context 'when the worker takes no arguments' do
      let(:args) { [] }

      it_behaves_like 'perform'
    end
  end
end
