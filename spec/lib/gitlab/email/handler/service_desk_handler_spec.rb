require 'spec_helper'
require_relative '../email_shared_blocks'

describe Gitlab::Email::Handler::EE::ServiceDeskHandler do
  include_context :email_shared_context
  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { fixture_file('emails/service_desk.eml') }
  let(:project) { create(:project, :public) }

  context 'when service desk is enabled' do
    before do
      project.update(service_desk_enabled: true)
      project.update(service_desk_mail_key: 'somemailkey')

      allow(Notify).to receive(:service_desk_thank_you_email)
        .with(instance_of(Integer)).and_return(double(deliver_later!: true))
    end

    it 'receives the email and creates issue' do
      setup_attachment

      expect(Notify).to receive(:service_desk_thank_you_email).with(instance_of(Integer))

      expect { receiver.execute }.to change { Issue.count }.by(1)

      new_issue = Issue.last

      expect(new_issue.author).to eql(User.support_bot)
      expect(new_issue.confidential?).to be true
      expect(new_issue.all_references.all).to be_empty
      expect(new_issue.title).to eq("Service Desk (from jake@adventuretime.ooo): The message subject! @all")
      expect(new_issue.description).to eq("Service desk stuff!\n\n```\na = b\n```\n\n![image](uploads/image.png)")
    end

    context 'when there is no from address' do
      before do
        allow_any_instance_of(described_class).to receive(:from_address)
          .and_return(nil)
      end

      it "creates issue and does not send thank you email" do
        expect(Notify).not_to receive(:service_desk_thank_you_email)

        expect { receiver.execute }.to change { Issue.count }.by(1)
      end
    end
  end

  context 'when service desk is not enabled' do
    before do
      project.update_attributes(
        service_desk_enabled: false,
        service_desk_mail_key: 'somemailkey',
      )
    end

    it 'bounces the email' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::ProcessingError)
    end

    it 'doesn\'t create an issue' do
      expect { receiver.execute rescue nil }.not_to change { Issue.count }
    end
  end
end
