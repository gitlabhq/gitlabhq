# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::LastUsedService, feature_category: :system_access do
  include ExclusiveLeaseHelpers

  describe '#execute' do
    subject { described_class.new(personal_access_token).execute }

    context 'when the personal access token was used 10 minutes ago', :freeze_time do
      let(:personal_access_token) { create(:personal_access_token, last_used_at: 10.minutes.ago) }

      it 'updates the last_used_at timestamp' do
        expect { subject }.to change { personal_access_token.last_used_at }
      end

      it 'obtains an exclusive lease before updating' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:set).with(
            "#{Gitlab::ExclusiveLease::PREFIX}:pat:last_used_update_lock:#{personal_access_token.id}",
            anything,
            nx: true,
            ex: described_class::LEASE_TIMEOUT
          ).and_call_original
        end

        expect { subject }.to change { personal_access_token.last_used_at }
      end

      it 'does not run on read-only GitLab instances' do
        allow(::Gitlab::Database).to receive(:read_only?).and_return(true)

        expect { subject }.not_to change { personal_access_token.last_used_at }
      end

      context 'when lease is already acquired by another process' do
        let(:lease_key) { "pat:last_used_update_lock:#{personal_access_token.id}" }

        before do
          stub_exclusive_lease_taken(lease_key, timeout: described_class::LEASE_TIMEOUT)
        end

        it 'does not update last_used_at' do
          expect { subject }.not_to change { personal_access_token.last_used_at }
        end
      end

      context 'when use_lease_for_pat_last_used_update flag is disabled' do
        before do
          stub_feature_flags(use_lease_for_pat_last_used_update: false)
        end

        it 'does not obtain an exclusive lease before updating' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).not_to receive(:set).with(
              "#{Gitlab::ExclusiveLease::PREFIX}:pat:last_used_update_lock:#{personal_access_token.id}",
              anything,
              nx: true,
              ex: described_class::LEASE_TIMEOUT
            )
          end

          expect { subject }.to change { personal_access_token.last_used_at }
        end
      end

      context 'when database load balancing is configured' do
        let!(:service) { described_class.new(personal_access_token) }

        it 'does not stick to primary' do
          ::Gitlab::Database::LoadBalancing::Session.clear_session

          expect(::Gitlab::Database::LoadBalancing::Session.current).not_to be_performed_write
          expect { service.execute }.to change { personal_access_token.last_used_at }
          expect(::Gitlab::Database::LoadBalancing::Session.current).to be_performed_write
          expect(::Gitlab::Database::LoadBalancing::Session.current).not_to be_using_primary
        end
      end
    end

    context 'when the personal access token was used less than 10 minutes ago', :freeze_time do
      let(:personal_access_token) { create(:personal_access_token, last_used_at: (10.minutes - 1.second).ago) }

      it 'does not update the last_used_at timestamp' do
        expect { subject }.not_to change { personal_access_token.last_used_at }
      end
    end

    context 'when the last_used_at timestamp is nil' do
      let_it_be(:personal_access_token) { create(:personal_access_token, last_used_at: nil) }

      it 'updates the last_used_at timestamp' do
        expect { subject }.to change { personal_access_token.last_used_at }
      end
    end

    context 'when not a personal access token' do
      let_it_be(:personal_access_token) { create(:oauth_access_token) }

      it 'does not execute' do
        expect(subject).to be_nil
      end
    end
  end
end
