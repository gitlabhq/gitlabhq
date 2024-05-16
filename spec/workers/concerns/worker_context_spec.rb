# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkerContext, feature_category: :shared do
  let(:worker) do
    Class.new do
      def self.name
        "TestWorker"
      end

      include ApplicationWorker
    end
  end

  before do
    stub_const(worker.name, worker)
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

  shared_examples 'tracking bulk scheduling contexts' do
    describe "context contents" do
      before do
        # stub clearing the contexts, so we can check what's inside
        allow(worker).to receive(:batch_context=).and_call_original
        allow(worker).to receive(:batch_context=).with(nil)
      end

      it 'keeps track of the context per key to schedule' do
        subject

        expect(worker.context_for_arguments(["hello"])).to be_a(Gitlab::ApplicationContext)
      end

      it 'does not share contexts across threads' do
        t1_context = nil
        t2_context = nil

        Thread.new do
          subject

          t1_context = worker.context_for_arguments(["hello"])
        end.join
        Thread.new do
          t2_context = worker.context_for_arguments(["hello"])
        end.join

        expect(t1_context).to be_a(Gitlab::ApplicationContext)
        expect(t2_context).to be_nil
      end
    end

    it 'clears the contexts' do
      subject

      expect(worker.__send__(:batch_context)).to be_nil
    end
  end

  describe '.bulk_perform_async_with_contexts' do
    subject do
      worker.bulk_perform_async_with_contexts(
        %w[hello world],
        context_proc: ->(_) { { user: build_stubbed(:user) } },
        arguments_proc: ->(word) { word }
      )
    end

    it 'calls bulk_perform_async with the arguments' do
      expect(worker).to receive(:bulk_perform_async).with([["hello"], ["world"]])

      subject
    end

    it_behaves_like 'tracking bulk scheduling contexts'
  end

  describe '.bulk_perform_in_with_contexts' do
    subject do
      worker.bulk_perform_in_with_contexts(
        10.minutes,
        %w[hello world],
        context_proc: ->(_) { { user: build_stubbed(:user) } },
        arguments_proc: ->(word) { word }
      )
    end

    it 'calls bulk_perform_in with the arguments and delay' do
      expect(worker).to receive(:bulk_perform_in).with(10.minutes, [["hello"], ["world"]])

      subject
    end

    it_behaves_like 'tracking bulk scheduling contexts'
  end

  describe '#with_context' do
    it 'allows modifying context when the job is running' do
      worker.new.with_context(user: build_stubbed(:user, username: 'jane-doe')) do
        expect(Gitlab::ApplicationContext.current).to include('meta.user' => 'jane-doe')
      end
    end

    it 'yields the arguments to the block' do
      a_user = build_stubbed(:user)
      a_project = build_stubbed(:project)

      worker.new.with_context(user: a_user, project: a_project) do |user:, project:|
        expect(user).to eq(a_user)
        expect(project).to eq(a_project)
      end
    end
  end
end
