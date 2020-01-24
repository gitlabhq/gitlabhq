# frozen_string_literal: true

require 'spec_helper'

describe WorkerContext do
  let(:worker) do
    Class.new do
      include WorkerContext
    end
  end

  describe '.worker_context' do
    it 'allows modifying the context for the entire worker' do
      worker.worker_context(user: build_stubbed(:user))

      expect(worker.get_worker_context).to be_a(Gitlab::ApplicationContext)
    end

    it 'allows fetches the context from a superclass if none was defined' do
      worker.worker_context(user: build_stubbed(:user))
      subclass = Class.new(worker)

      expect(subclass.get_worker_context).to eq(worker.get_worker_context)
    end
  end

  describe '#with_context' do
    it 'allows modifying context when the job is running' do
      worker.new.with_context(user: build_stubbed(:user, username: 'jane-doe')) do
        expect(Labkit::Context.current.to_h).to include('meta.user' => 'jane-doe')
      end
    end
  end
end
