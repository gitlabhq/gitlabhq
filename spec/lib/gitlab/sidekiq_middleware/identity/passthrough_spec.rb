# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Identity::Passthrough, :request_store, feature_category: :system_access do
  let_it_be(:primary_user) { create(:user) }
  let_it_be(:scoped_user) { create(:user) }

  let(:worker) { Class.new }
  let(:job) { { 'jid' => 123 } }
  let(:queue) { 'test_queue' }

  subject(:middleware) { described_class.new }

  describe '#call' do
    context 'when composite identity is linked' do
      before do
        ::Gitlab::Auth::Identity.new(primary_user).link!(scoped_user)
      end

      context 'when user has a composite identity' do
        before do
          allow(primary_user).to receive(:composite_identity_enforced).and_return(true)
        end

        it 'adds composite identity to job payload' do
          expect { |b| middleware.call(worker, job, queue, nil, &b) }.to yield_control

          expect(::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG).to eq 'sqci'
          expect(job['sqci']).to eq([primary_user.id, scoped_user.id])
        end
      end

      context 'when user does not have composite identity' do
        it 'does not modify job payload' do
          expect { |b| middleware.call(worker, job, queue, nil, &b) }.to yield_control

          expect(job[::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG]).to be_nil
        end
      end
    end

    context 'when composite identity has not been linked' do
      it 'does not modify job payload' do
        expect { |b| middleware.call(worker, job, queue, nil, &b) }.to yield_control

        expect(job[::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG]).to be_nil
      end
    end
  end
end
