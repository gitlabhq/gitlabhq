# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::LastUsedService, feature_category: :system_access do
  include ExclusiveLeaseHelpers

  describe '#execute' do
    subject(:service_execution) { described_class.new(personal_access_token).execute }

    context 'when the personal access token was used 10 minutes ago', :freeze_time do
      let(:personal_access_token) { create(:personal_access_token, last_used_at: 10.minutes.ago) }

      it 'updates the last_used_at timestamp' do
        expect { service_execution }.to change { personal_access_token.last_used_at }
      end

      context 'when client is using ipv4' do
        let(:current_ip_address) { '127.0.0.1' }

        it "does update the personal access token's last used ips" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.to change { personal_access_token.last_used_ips.count }
          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
              .exists?
          ).to be_truthy
        end
      end

      context 'when client is using ipv6' do
        let(:current_ip_address) { '::1' }

        it "does update the personal access token's last used ips" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.to change { personal_access_token.last_used_ips.count }
          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
              .exists?
          ).to be_truthy
        end
      end

      context 'when PAT IP feature flag is disabled' do
        let(:current_ip_address) { '127.0.0.1' }

        before do
          stub_feature_flags(pat_ip: false)
        end

        it "does not update the personal access token's last used ips" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.not_to change { personal_access_token.last_used_ips.count }
          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
              .exists?
          ).to be_falsy
        end
      end

      context 'when the personal access token was used more than 1 minute ago', :freeze_time do
        let(:current_ip_address) { '::1' }
        let(:personal_access_token) { create(:personal_access_token, last_used_at: 2.minutes.ago) }

        it "updates the personal access token's last used ips" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.to change { personal_access_token.last_used_ips.count }
          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
              .exists?
          ).to be_truthy
        end
      end

      context 'when the personal access token was used less than 1 minute ago', :freeze_time do
        let(:current_ip_address) { '::1' }
        let(:personal_access_token) { create(:personal_access_token, last_used_at: 30.seconds.ago) }

        it "does not update the personal access token's last used ips" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.not_to change { personal_access_token.last_used_ips.count }
          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
              .exists?
          ).to be_falsy
        end
      end

      context "when the current ip address is already saved" do
        let(:current_ip_address) { '::1' }

        before do
          personal_access_token.last_used_ips << Authn::PersonalAccessTokenLastUsedIp.new(
            organization: personal_access_token.organization,
            ip_address: current_ip_address)
        end

        context "when the timestamp does not need an update" do
          it "does not update the database" do
            expect(Authn::PersonalAccessTokenLastUsedIp).not_to receive(:new)

            service_execution
          end
        end

        context "when timestamp needs an update", :freeze_time do
          let(:personal_access_token) { create(:personal_access_token, last_used_at: 11.minutes.ago) }

          it "does update the timestamp, but does not update the ip" do
            allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

            expect(personal_access_token.last_used_ips.count).to eq(1)
            expect { service_execution }.to change { personal_access_token.last_used_at }
            expect(personal_access_token.last_used_ips.count).to eq(1)
          end
        end
      end

      context "when the count of personal access token's last used ips are above the limit" do
        let(:current_ip_address) { '123.12.123.1' }

        before do
          1.upto(5) do |i|
            personal_access_token.last_used_ips << Authn::PersonalAccessTokenLastUsedIp.new(
              organization: personal_access_token.organization,
              ip_address: "127.0.0.#{i}", created_at: i.days.ago)
          end
        end

        it "keeps no. of ips at 5" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect(
            Authn::PersonalAccessTokenLastUsedIp
              .where(personal_access_token_id: personal_access_token.id, ip_address: "127.0.0.5")
              .exists?
          ).to be_truthy
          expect { service_execution }.not_to change { personal_access_token.last_used_ips.count }
        end

        it "removes the oldest PAT ip" do
          allow(Gitlab::IpAddressState).to receive(:current).and_return(current_ip_address)

          expect { service_execution }.to(
            change do
              Authn::PersonalAccessTokenLastUsedIp
                .where(personal_access_token_id: personal_access_token.id, ip_address: "127.0.0.5")
                .exists?
            end.from(true).to(false))
        end
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

        expect { service_execution }.to change { personal_access_token.last_used_at }
      end

      it 'does not run on read-only GitLab instances' do
        allow(::Gitlab::Database).to receive(:read_only?).and_return(true)

        expect { service_execution }.not_to change { personal_access_token.last_used_at }
      end

      context 'when lease is already acquired by another process' do
        let(:lease_key) { "pat:last_used_update_lock:#{personal_access_token.id}" }

        before do
          stub_exclusive_lease_taken(lease_key, timeout: described_class::LEASE_TIMEOUT)
        end

        it 'does not update last_used_at' do
          expect { service_execution }.not_to change { personal_access_token.last_used_at }
        end
      end

      context 'when database load balancing is configured' do
        let!(:service) { described_class.new(personal_access_token) }
        let(:lb) { personal_access_token.load_balancer }

        it 'does not stick to primary' do
          ::Gitlab::Database::LoadBalancing::SessionMap.clear_session

          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).not_to be_performed_write
          expect { service.execute }.to change { personal_access_token.last_used_at }
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).to be_performed_write
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).not_to be_using_primary
        end
      end
    end

    context 'when the personal access token was used less than 10 minutes ago', :freeze_time do
      let(:personal_access_token) { create(:personal_access_token, last_used_at: (10.minutes - 1.second).ago) }

      it 'does not update the last_used_at timestamp' do
        expect { service_execution }.not_to change { personal_access_token.last_used_at }
      end
    end

    context 'when the last_used_at timestamp is nil' do
      let_it_be(:personal_access_token) { create(:personal_access_token, last_used_at: nil) }

      it 'updates the last_used_at timestamp' do
        expect { service_execution }.to change { personal_access_token.last_used_at }
      end
    end

    context 'when not a personal access token' do
      let_it_be(:personal_access_token) { create(:oauth_access_token) }

      it 'does not execute' do
        expect(service_execution).to be_nil
      end
    end
  end
end
