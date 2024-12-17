# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VerifyPagesDomainService, feature_category: :pages do
  using RSpec::Parameterized::TableSyntax
  include EmailHelpers

  let(:service) { described_class.new(domain) }

  describe '#execute' do
    subject(:service_response) { service.execute }

    where(:domain_sym, :code_sym) do
      :domain              | :verification_code
      :domain              | :keyed_verification_code

      :verification_domain | :verification_code
      :verification_domain | :keyed_verification_code
    end

    with_them do
      let(:domain_name) { domain.send(domain_sym) }
      let(:verification_code) { domain.send(code_sym) }

      shared_examples 'verifies and enables the domain' do
        it_behaves_like 'returning a success service response'

        it 'verifies and enables the domain' do
          service_response

          expect(domain).to be_verified
          expect(domain).to be_enabled
          expect(domain.remove_at).to be_nil
        end
      end

      shared_examples 'successful enablement and verification' do
        context 'when txt record contains verification code' do
          before do
            stub_resolver(domain_name => ['something else', verification_code])
          end

          include_examples 'verifies and enables the domain'
        end

        context 'when txt record contains verification code with other text' do
          before do
            stub_resolver(domain_name => "something #{verification_code} else")
          end

          include_examples 'verifies and enables the domain'
        end
      end

      shared_examples 'unverifies and disables domain' do
        let(:error_message) { "Couldn't verify #{domain.domain}" }

        it_behaves_like 'returning an error service response'
        it { is_expected.to have_attributes message: error_message }

        it 'unverifies domain' do
          service_response

          expect(domain).not_to be_verified
        end

        it 'disables domain and shedules it for removal in 1 week' do
          service_response

          expect(domain).not_to be_enabled

          expect(domain.remove_at).to be_like_time(7.days.from_now)
        end
      end

      context 'when domain is disabled (or new)' do
        let(:domain) { create(:pages_domain, :disabled) }

        include_examples 'successful enablement and verification'

        context 'when txt record does not contain verification code' do
          before do
            stub_resolver(domain_name => 'something else')
          end

          include_examples 'unverifies and disables domain'
        end

        context 'when no txt records are present' do
          before do
            stub_resolver
          end

          include_examples 'unverifies and disables domain'
        end
      end

      context 'when domain is verified' do
        let(:domain) { create(:pages_domain) }

        include_examples 'successful enablement and verification'

        shared_examples 'unverifing domain' do
          it_behaves_like 'returning an error service response'
          it { is_expected.to have_attributes message: "Couldn't verify #{domain.domain}" }

          it 'unverifies but does not disable domain' do
            service_response

            expect(domain).not_to be_verified
            expect(domain).to be_enabled
          end

          it 'does not schedule domain for removal' do
            service_response

            expect(domain.remove_at).to be_nil
          end
        end

        context 'when txt record does not contain verification code' do
          before do
            stub_resolver(domain_name => 'something else')
          end

          include_examples 'unverifing domain'
        end

        context 'when no txt records are present' do
          before do
            stub_resolver
          end

          include_examples 'unverifing domain'
        end
      end

      context 'when domain is expired' do
        let(:domain) { create(:pages_domain, :expired) }

        context 'when the right code is present' do
          before do
            stub_resolver(domain_name => domain.keyed_verification_code)
          end

          include_examples 'verifies and enables the domain'
        end

        context 'when the right code is not present' do
          before do
            stub_resolver
          end

          include_examples 'unverifies and disables domain' do
            let(:error_message) { "Couldn't verify #{domain.domain}. It is now disabled." }
          end
        end
      end

      context 'when domain is disabled and scheduled for removal' do
        let(:domain) { create(:pages_domain, :disabled, :scheduled_for_removal) }

        context 'when the right code is present' do
          before do
            stub_resolver(domain.domain => domain.keyed_verification_code)
          end

          it_behaves_like 'returning a success service response'

          it 'verifies and enables domain' do
            service_response

            expect(domain).to be_verified
            expect(domain).to be_enabled
          end

          it 'prevent domain from being removed' do
            expect { service_response }.to change { domain.remove_at }.to(nil)
          end
        end

        context 'when the right code is not present' do
          before do
            stub_resolver
          end

          it 'keeps domain scheduled for removal but does not change removal time' do
            expect { service_response }.not_to change { domain.remove_at }
            expect(domain.remove_at).to be_present
          end
        end
      end

      context 'invalid domain' do
        let(:domain) { build(:pages_domain, :expired, :with_missing_chain) }

        before do
          domain.save!(validate: false)
          stub_resolver
        end

        it_behaves_like 'returning an error service response'
        it { is_expected.to have_attributes(message: "Couldn't verify #{domain.domain}. It is now disabled.") }

        it 'can be disabled' do
          service_response

          expect(domain).not_to be_verified
          expect(domain).not_to be_enabled
        end
      end
    end

    context 'timeout behaviour' do
      let(:domain) { create(:pages_domain) }

      it 'sets a timeout on the DNS query' do
        expect(stub_resolver).to receive(:timeouts=).with(described_class::RESOLVER_TIMEOUT_SECONDS)

        service_response
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
          allow(NotificationService).to receive(:new).and_return(notification_service)

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

          service_response
        end
      end

      context 'pages verification disabled' do
        let(:domain) { create(:pages_domain, :disabled) }

        before do
          allow(NotificationService).to receive(:new).and_return(notification_service)

          stub_application_setting(pages_domain_verification_enabled: false)
        end

        it 'skips email notifications' do
          expect(notification_service).not_to receive(:pages_domain_enabled)

          service_response
        end
      end
    end

    context 'no verification code' do
      let(:domain) { build(:pages_domain, verification_code: '') }

      before do
        disallow_resolver!
      end

      it_behaves_like 'returning an error service response'
      it { is_expected.to have_attributes(message: "No verification code set for #{domain.domain}") }
    end

    context 'pages domain verification is disabled' do
      let(:domain) { create(:pages_domain, :disabled) }

      before do
        stub_application_setting(pages_domain_verification_enabled: false)
      end

      it 'extends domain validity by unconditionally reverifying' do
        disallow_resolver!

        service_response

        expect(domain).to be_verified
        expect(domain).to be_enabled
      end

      it 'does not shorten any grace period' do
        grace = Time.current + 1.year
        domain.update!(enabled_until: grace)
        disallow_resolver!

        service_response

        expect(domain.enabled_until).to be_like_time(grace)
      end
    end
  end

  def disallow_resolver!
    expect(Resolv::DNS).not_to receive(:open)
  end
end
