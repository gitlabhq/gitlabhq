require 'spec_helper'

describe VerifyPagesDomainService do
  using RSpec::Parameterized::TableSyntax
  include EmailHelpers

  let(:error_status) { { status: :error, message: "Couldn't verify #{domain.domain}" } }

  subject(:service) { described_class.new(domain) }

  describe '#execute' do
    context 'verification code recognition (verified domain)' do
      where(:domain_sym, :code_sym) do
        :domain | :verification_code
        :domain | :keyed_verification_code

        :verification_domain | :verification_code
        :verification_domain | :keyed_verification_code
      end

      with_them do
        set(:domain) { create(:pages_domain) }

        let(:domain_name) { domain.send(domain_sym) }
        let(:verification_code) { domain.send(code_sym) }

        it 'verifies and enables the domain' do
          stub_resolver(domain_name => ['something else', verification_code])

          expect(service.execute).to eq(status: :success)
          expect(domain).to be_verified
          expect(domain).to be_enabled
        end

        it 'verifies and enables when the code is contained partway through a TXT record' do
          stub_resolver(domain_name => "something #{verification_code} else")

          expect(service.execute).to eq(status: :success)
          expect(domain).to be_verified
          expect(domain).to be_enabled
        end

        it 'does not verify when the code is not present' do
          stub_resolver(domain_name => 'something else')

          expect(service.execute).to eq(error_status)

          expect(domain).not_to be_verified
          expect(domain).to be_enabled
        end
      end

      context 'verified domain' do
        set(:domain) { create(:pages_domain) }

        it 'unverifies (but does not disable) when the right code is not present' do
          stub_resolver(domain.domain => 'something else')

          expect(service.execute).to eq(error_status)
          expect(domain).not_to be_verified
          expect(domain).to be_enabled
        end

        it 'unverifies (but does not disable) when no records are present' do
          stub_resolver

          expect(service.execute).to eq(error_status)
          expect(domain).not_to be_verified
          expect(domain).to be_enabled
        end
      end

      context 'expired domain' do
        set(:domain) { create(:pages_domain, :expired) }

        it 'verifies and enables when the right code is present' do
          stub_resolver(domain.domain => domain.keyed_verification_code)

          expect(service.execute).to eq(status: :success)

          expect(domain).to be_verified
          expect(domain).to be_enabled
        end

        it 'disables when the right code is not present' do
          error_status[:message] += '. It is now disabled.'

          stub_resolver

          expect(service.execute).to eq(error_status)

          expect(domain).not_to be_verified
          expect(domain).not_to be_enabled
        end
      end

      context 'invalid domain' do
        let(:domain) { build(:pages_domain, :expired, :with_missing_chain) }

        before do
          domain.save(validate: false)
        end

        it 'can be disabled' do
          error_status[:message] += '. It is now disabled.'

          stub_resolver

          expect(service.execute).to eq(error_status)

          expect(domain).not_to be_verified
          expect(domain).not_to be_enabled
        end
      end
    end

    context 'timeout behaviour' do
      let(:domain) { create(:pages_domain) }

      it 'sets a timeout on the DNS query' do
        expect(stub_resolver).to receive(:timeouts=).with(described_class::RESOLVER_TIMEOUT_SECONDS)

        service.execute
      end
    end

    context 'email notifications' do
      let(:notification_service) { instance_double('NotificationService') }

      where(:factory, :verification_succeeds, :expected_notification) do
        nil         | true  | nil
        nil         | false | :verification_failed
        :reverify   | true  | nil
        :reverify   | false | :verification_failed
        :unverified | true  | :verification_succeeded
        :unverified | false | nil
        :expired    | true  | nil
        :expired    | false | :disabled
        :disabled   | true  | :enabled
        :disabled   | false | nil
      end

      with_them do
        let(:domain) { create(:pages_domain, *[factory].compact) }

        before do
          allow(service).to receive(:notification_service) { notification_service }

          if verification_succeeds
            stub_resolver(domain.domain => domain.verification_code)
          else
            stub_resolver
          end
        end

        it 'sends a notification if appropriate' do
          if expected_notification
            expect(notification_service).to receive(:"pages_domain_#{expected_notification}").with(domain)
          end

          service.execute
        end
      end

      context 'pages verification disabled' do
        let(:domain) { create(:pages_domain, :disabled) }

        before do
          stub_application_setting(pages_domain_verification_enabled: false)
          allow(service).to receive(:notification_service) { notification_service }
        end

        it 'skips email notifications' do
          expect(notification_service).not_to receive(:pages_domain_enabled)

          service.execute
        end
      end
    end

    context 'pages configuration updates' do
      context 'enabling a disabled domain' do
        let(:domain) { create(:pages_domain, :disabled) }

        it 'schedules an update' do
          stub_resolver(domain.domain => domain.verification_code)

          expect(domain).to receive(:update_daemon)

          service.execute
        end
      end

      context 'verifying an enabled domain' do
        let(:domain) { create(:pages_domain) }

        it 'schedules an update' do
          stub_resolver(domain.domain => domain.verification_code)

          expect(domain).not_to receive(:update_daemon)

          service.execute
        end
      end

      context 'disabling an expired domain' do
        let(:domain) { create(:pages_domain, :expired) }

        it 'schedules an update' do
          stub_resolver

          expect(domain).to receive(:update_daemon)

          service.execute
        end
      end

      context 'failing to verify a disabled domain' do
        let(:domain) { create(:pages_domain, :disabled) }

        it 'does not schedule an update' do
          stub_resolver

          expect(domain).not_to receive(:update_daemon)

          service.execute
        end
      end
    end

    context 'no verification code' do
      let(:domain) { create(:pages_domain) }

      it 'returns an error' do
        domain.verification_code = ''

        disallow_resolver!

        expect(service.execute).to eq(status: :error, message: "No verification code set for #{domain.domain}")
      end
    end

    context 'pages domain verification is disabled' do
      let(:domain) { create(:pages_domain, :disabled) }

      before do
        stub_application_setting(pages_domain_verification_enabled: false)
      end

      it 'extends domain validity by unconditionally reverifying' do
        disallow_resolver!

        service.execute

        expect(domain).to be_verified
        expect(domain).to be_enabled
      end

      it 'does not shorten any grace period' do
        grace = Time.now + 1.year
        domain.update!(enabled_until: grace)
        disallow_resolver!

        service.execute

        expect(domain.enabled_until).to be_like_time(grace)
      end
    end
  end

  def disallow_resolver!
    expect(Resolv::DNS).not_to receive(:open)
  end

  def stub_resolver(stubbed_lookups = {})
    resolver = instance_double('Resolv::DNS')
    allow(resolver).to receive(:timeouts=)

    expect(Resolv::DNS).to receive(:open).and_yield(resolver)

    allow(resolver).to receive(:getresources) { [] }
    stubbed_lookups.each do |domain, records|
      records = Array(records).map { |txt| Resolv::DNS::Resource::IN::TXT.new(txt) }
      allow(resolver).to receive(:getresources).with(domain, Resolv::DNS::Resource::IN::TXT) { records }
    end

    resolver
  end
end
