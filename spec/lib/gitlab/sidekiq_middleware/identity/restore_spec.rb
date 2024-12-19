# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Identity::Restore, :request_store, feature_category: :system_access do
  let_it_be(:primary_user) { create(:user) }
  let_it_be(:scoped_user) { create(:user) }

  let(:job) { { 'jid' => 123 } }
  let(:queue) { 'test_queue' }
  let(:worker) do
    Class.new do
      include ::Sidekiq::Worker

      def perform(user_id)
        ::Gitlab::Auth::Identity.new(::User.find(user_id)).tap do |identity|
          raise ArgumentError unless identity.linked?
        end
      end
    end
  end

  subject(:middleware) { described_class.new }

  before do
    stub_const('TestIdentityWorker', worker)
  end

  describe '#call' do
    context 'when composite identity has been linked' do
      let(:job) { { 'jid' => 123, 'sqci' => [primary_user.id, scoped_user.id] } }

      it 'yields control' do
        expect { |b| middleware.call(worker.new, job, queue, &b) }.to yield_control
      end

      it 'restores composite identity' do
        middleware.call(worker.new, job, queue) do
          identity = ::Gitlab::Auth::Identity.new(primary_user)

          expect(identity).to be_linked
          expect(identity).to be_valid
          expect(identity.scoped_user).to eq(scoped_user)
        end
      end
    end

    context 'when composite identity has not been linked' do
      it 'restores composite identity' do
        middleware.call(worker.new, job, queue) do
          expect(::Gitlab::Auth::Identity.new(primary_user)).not_to be_linked
        end
      end
    end
  end

  describe 'composite identity restoration end-to-end' do
    before do
      allow_any_instance_of(::User).to receive(:composite_identity_enforced).and_return(true) # rubocop:disable RSpec/AnyInstanceOf -- works more reliably

      ::Gitlab::Auth::Identity.new(primary_user).link!(scoped_user)
    end

    it 'restores identity' do
      assertion = -> do
        Sidekiq::Testing.inline! do
          TestIdentityWorker.perform_async(primary_user.id)
        end
      end

      expect { assertion.call }.not_to raise_error
    end
  end
end
