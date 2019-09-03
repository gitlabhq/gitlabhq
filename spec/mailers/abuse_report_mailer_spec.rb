require 'spec_helper'

describe AbuseReportMailer do
  include EmailSpec::Matchers

  describe '.notify' do
    before do
      stub_application_setting(admin_notification_email: 'admin@example.com')
    end

    let(:report) { create(:abuse_report) }

    subject { described_class.notify(report.id) }

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    context 'with admin_notification_email set' do
      it 'sends to the admin_notification_email' do
        is_expected.to deliver_to 'admin@example.com'
      end

      it 'includes the user in the subject' do
        is_expected.to have_subject "#{report.user.name} (#{report.user.username}) was reported for abuse"
      end
    end

    context 'with no admin_notification_email set' do
      it 'returns early' do
        stub_application_setting(admin_notification_email: nil)

        expect { described_class.notify(spy).deliver_now }
          .not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
