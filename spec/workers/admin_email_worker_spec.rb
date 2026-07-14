# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdminEmailWorker, feature_category: :source_code_management do
  subject(:worker) { described_class.new }

  let_it_be(:admin) { create(:admin) }

  def stub_admin_recipients(emails)
    active_admins = double('active admins', pluck: emails) # rubocop:disable RSpec/VerifiedDoubles -- AR scopes are dynamic
    admins = double('admins', active: active_admins) # rubocop:disable RSpec/VerifiedDoubles -- AR scopes are dynamic

    allow(User).to receive(:admins).and_return(admins)
  end

  describe '.perform' do
    it 'does not attempt to send repository check mail when they are disabled' do
      stub_application_setting(repository_checks_enabled: false)

      expect(worker).not_to receive(:send_repository_check_mail)

      worker.perform
    end

    context 'when repository_checks are enabled' do
      before do
        stub_application_setting(repository_checks_enabled: true)
      end

      it 'checks if repository check mail should be sent' do
        expect(worker).to receive(:send_repository_check_mail)

        worker.perform
      end

      it 'does not send mail when there are no failed repos' do
        expect(RepositoryCheckMailer).not_to receive(:notify)

        worker.perform
      end

      it 'sends mail to each active admin when there is a failed repo' do
        create(:project, last_repository_check_failed: true, last_repository_check_at: Date.yesterday)

        expect(RepositoryCheckMailer).to receive(:notify).with(1, admin.email).and_return(spy)

        worker.perform
      end

      it 'excludes blocked admins from the recipients', :aggregate_failures do
        blocked_admin = create(:admin, :blocked)
        create(:project, last_repository_check_failed: true, last_repository_check_at: Date.yesterday)

        expect(RepositoryCheckMailer).to receive(:notify).with(1, admin.email).and_return(spy)
        expect(RepositoryCheckMailer).not_to receive(:notify).with(1, blocked_admin.email)

        worker.perform
      end

      context 'when one admin address is undeliverable' do
        it 'continues notifying the remaining admins and logs the failure', :aggregate_failures do
          undeliverable_admin = build_stubbed(:admin)
          deliverable_admin = build_stubbed(:admin)
          create(:project, last_repository_check_failed: true, last_repository_check_at: Date.yesterday)

          stub_admin_recipients([undeliverable_admin.email, deliverable_admin.email])

          undeliverable_mail = instance_double(ActionMailer::MessageDelivery)
          deliverable_mail = instance_double(ActionMailer::MessageDelivery)

          allow(RepositoryCheckMailer).to receive(:notify).with(1, undeliverable_admin.email)
            .and_return(undeliverable_mail)
          allow(RepositoryCheckMailer).to receive(:notify).with(1, deliverable_admin.email)
            .and_return(deliverable_mail)
          allow(undeliverable_mail).to receive(:deliver_now).and_raise(Net::SMTPFatalError.new('550 rejected'))
          allow(deliverable_mail).to receive(:deliver_now)

          expect(worker.logger).to receive(:info).with(
            hash_including('recipient' => undeliverable_admin.email)
          )

          expect { worker.perform }.not_to raise_error
          expect(deliverable_mail).to have_received(:deliver_now)
        end
      end

      context 'when delivery raises a transient error' do
        it 'lets the retryable error propagate so Sidekiq can retry' do
          create(:project, last_repository_check_failed: true, last_repository_check_at: Date.yesterday)

          mail = instance_double(ActionMailer::MessageDelivery)

          allow(RepositoryCheckMailer).to receive(:notify).with(1, admin.email).and_return(mail)
          allow(mail).to receive(:deliver_now).and_raise(ApplicationMailer::SMTPConnectionError)

          expect { worker.perform }.to raise_error(ApplicationMailer::SMTPConnectionError)
        end
      end
    end
  end
end
