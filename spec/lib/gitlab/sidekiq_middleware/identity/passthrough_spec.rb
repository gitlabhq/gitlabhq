# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Identity::Passthrough, :request_store, feature_category: :system_access do
  let_it_be_with_reload(:primary_user) { create(:user, :service_account) }
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
          primary_user.update!(composite_identity_enforced: true)
        end

        it 'adds composite identity to job payload' do
          expect { |b| middleware.call(worker, job, queue, nil, &b) }.to yield_control

          expect(::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG).to eq 'sqci'
          expect(job['sqci']).to eq([primary_user.id, scoped_user.id])
        end

        context 'when worker has skip_composite_identity_passthrough!' do
          let(:worker_class) do
            Class.new do
              def self.name
                'TestWorkerWithSkipPassthrough'
              end

              include ApplicationWorker

              skip_composite_identity_passthrough!
            end
          end

          let(:worker) { worker_class }

          it 'does not add composite identity to job payload' do
            expect { |b| middleware.call(worker, job, queue, nil, &b) }.to yield_control

            expect(job[::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG]).to be_nil
          end
        end

        context 'when worker class is passed as a string' do
          let(:worker_class) do
            Class.new do
              def self.name
                'TestWorkerWithSkipPassthroughString'
              end

              include ApplicationWorker

              skip_composite_identity_passthrough!
            end
          end

          before do
            stub_const('TestWorkerWithSkipPassthroughString', worker_class)
          end

          it 'does not add composite identity to job payload' do
            expect { |b| middleware.call('TestWorkerWithSkipPassthroughString', job, queue, nil, &b) }.to yield_control

            expect(job[::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_SIDEKIQ_ARG]).to be_nil
          end
        end

        context 'when worker class string cannot be constantized' do
          it 'adds composite identity to job payload' do
            expect { |b| middleware.call('NonExistentWorkerClass', job, queue, nil, &b) }.to yield_control

            expect(job['sqci']).to eq([primary_user.id, scoped_user.id])
          end
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
