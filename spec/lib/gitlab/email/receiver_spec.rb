# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Receiver, feature_category: :shared do
  include_context 'email shared context'

  let_it_be_with_reload(:project) { create(:project) }
  let(:metric_transaction) { instance_double(Gitlab::Metrics::WebTransaction) }

  shared_examples 'successful receive' do
    let(:handler) { double(:handler, project: project, execute: true, metrics_event: nil, metrics_params: nil) }
    let(:client_id) { 'email/jake@example.com' }
    let(:mail_key) { 'gitlabhq/gitlabhq+auth_token' }

    it 'correctly finds the mail key' do
      expect(Gitlab::Email::Handler).to receive(:for).with(an_instance_of(Mail::Message), mail_key).and_return(handler)

      receiver.execute
    end

    it 'adds metric event' do
      allow(receiver).to receive(:handler).and_return(handler)

      expect(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
      expect(metric_transaction).to receive(:add_event).with(handler.metrics_event, handler.metrics_params)

      receiver.execute
    end

    it 'returns valid metadata' do
      allow(receiver).to receive(:handler).and_return(handler)

      metadata = receiver.mail_metadata

      expect(metadata.keys).to match_array(%i[mail_uid from_address to_address mail_key references delivered_to envelope_to x_envelope_to meta received_recipients cc_address])
      expect(metadata[:meta]).to include(client_id: client_id, project: project.full_path)
      expect(metadata[meta_key]).to eq(meta_value)
    end
  end

  shared_examples 'failed receive with event' do
    it 'adds metric event' do
      expect(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
      expect(metric_transaction).to receive(:add_event).with('email_receiver_error', { error: expected_error.name })

      expect { receiver.execute }.to raise_error(expected_error)
    end
  end

  shared_examples 'failed receive without event' do
    it 'adds metric event' do
      expect(::Gitlab::Metrics::BackgroundTransaction).not_to receive(:current)

      expect { receiver.execute }.to raise_error(expected_error)
    end
  end

  context 'when the email contains a valid email address in a header' do
    before do
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.example.com")
    end

    context 'when in a Delivered-To header' do
      let(:email_raw) { fixture_file('emails/forwarded_new_issue.eml') }
      let(:meta_key) { :delivered_to }
      let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com", "support@example.com"] }

      it_behaves_like 'successful receive'
    end

    context 'when in an Envelope-To header' do
      let(:email_raw) { fixture_file('emails/envelope_to_header.eml') }
      let(:meta_key) { :envelope_to }
      let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com"] }

      it_behaves_like 'successful receive'
    end

    context 'when in an X-Envelope-To header' do
      let(:email_raw) { fixture_file('emails/x_envelope_to_header.eml') }
      let(:meta_key) { :x_envelope_to }
      let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com"] }

      it_behaves_like 'successful receive'
    end

    context 'when enclosed with angle brackets in an Envelope-To header' do
      let(:email_raw) { fixture_file('emails/envelope_to_header_with_angle_brackets.eml') }
      let(:meta_key) { :envelope_to }
      let(:meta_value) { ["<incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com>"] }

      it_behaves_like 'successful receive'
    end

    context 'when mail key is in the references header with a comma' do
      let(:email_raw) { fixture_file('emails/valid_reply_with_references_in_comma.eml') }
      let(:meta_key) { :references }
      let(:meta_value) { ['"<reply-59d8df8370b7e95c5a49fbf86aeb2c93@localhost>,<issue_1@localhost>,<exchange@microsoft.com>"'] }

      it_behaves_like 'successful receive' do
        let(:mail_key) { '59d8df8370b7e95c5a49fbf86aeb2c93' }
      end
    end

    context 'when all other headers are missing' do
      let(:email_raw) { fixture_file('emails/missing_delivered_to_header.eml') }
      let(:meta_key) { :received_recipients }
      let(:meta_value) { ['incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com', 'incoming+gitlabhq/gitlabhq@example.com'] }

      describe 'it uses receive headers to find the key' do
        it_behaves_like 'successful receive'
      end
    end

    context 'when in a Cc header' do
      let(:email_raw) do
        <<~EMAIL
        From: jake@example.com
        To: to@example.com
        Cc: incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com
        Subject: Issue titile

        Issue description
        EMAIL
      end

      let(:meta_key) { :cc_address }
      let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com"] }

      it_behaves_like 'successful receive'
    end

    context 'when Service Desk custom email reply address in To header and no References header exists' do
      let_it_be_with_refind(:setting) { create(:service_desk_setting, project: project, add_external_participants_from_cc: true) }

      let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
      let!(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }
      let(:incoming_email) { "incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com" }
      let(:reply_key) { "5de1a83a6fc3c9fe34d756c7f484159e" }
      let(:custom_email_reply) { "support+#{reply_key}@example.com" }

      context 'when custom email is enabled' do
        let(:email_raw) do
          <<~EMAIL
          Delivered-To: #{incoming_email}
          From: jake@example.com
          To: #{custom_email_reply}
          Subject: Reply titile

          Reply body
          EMAIL
        end

        let(:meta_key) { :to_address }
        let(:meta_value) { [custom_email_reply] }

        before do
          project.reset
          setting.update!(custom_email: 'support@example.com', custom_email_enabled: true)
        end

        it_behaves_like 'successful receive' do
          let(:mail_key) { reply_key }
        end

        # Email forwarding using a transport rule in Microsoft 365 adds the forwarding
        # target to the `To` header. We have to select te custom email reply address
        # before the incoming address (forwarding target)
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/426269#note_1629170865 for email structure
        context 'when also Service Desk incoming address in To header' do
          let(:email_raw) do
            <<~EMAIL
            From: jake@example.com
            To: #{custom_email_reply}, #{incoming_email}
            Subject: Reply titile

            Reply body
            EMAIL
          end

          let(:meta_value) { [custom_email_reply, incoming_email] }

          it_behaves_like 'successful receive' do
            let(:mail_key) { reply_key }
          end
        end
      end
    end
  end

  context 'when we cannot find a capable handler' do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, '!!!') }
    let(:expected_error) { Gitlab::Email::UnknownIncomingEmail }

    it_behaves_like 'failed receive with event'
  end

  context 'when the email is blank' do
    let(:email_raw) { '' }
    let(:expected_error) { Gitlab::Email::EmptyEmailError }

    it_behaves_like 'failed receive without event'
  end

  context 'when the email was auto generated with Auto-Submitted header' do
    let(:email_raw) { fixture_file('emails/auto_submitted.eml') }
    let(:expected_error) { Gitlab::Email::AutoGeneratedEmailError }

    it_behaves_like 'failed receive without event'
  end

  context "when the email's To field is blank" do
    before do
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.example.com")
    end

    let(:email_raw) do
      <<~EMAIL
      Delivered-To: incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com
      From: "jake@example.com" <jake@example.com>
      Bcc: "support@example.com" <support@example.com>

      Email content
      EMAIL
    end

    let(:meta_key) { :delivered_to }
    let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com"] }

    it_behaves_like 'successful receive'
  end

  context "when the email's From field is blank" do
    before do
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.example.com")
    end

    let(:email_raw) do
      <<~EMAIL
      Delivered-To: incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com
      To: "support@example.com" <support@example.com>

      Email content
      EMAIL
    end

    let(:meta_key) { :delivered_to }
    let(:meta_value) { ["incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com"] }

    it_behaves_like 'successful receive' do
      let(:client_id) { 'email/' }
    end
  end

  context 'when the email was auto generated with X-Autoreply header' do
    let(:email_raw) { fixture_file('emails/auto_reply.eml') }
    let(:expected_error) { Gitlab::Email::AutoGeneratedEmailError }

    it_behaves_like 'failed receive without event'
  end

  describe 'event raising via errors' do
    let(:handler) { double(:handler, project: project, execute: true, metrics_event: nil, metrics_params: nil) }
    let(:email_raw) { "arbitrary text. could be anything really. we're going to raise an error anyway." }

    before do
      allow(receiver).to receive(:handler).and_return(handler)
      allow(handler).to receive(:execute).and_raise(expected_error)
    end

    describe 'handling errors which do not raise events' do
      where(:expected_error) do
        [
          Gitlab::Email::AutoGeneratedEmailError,
          Gitlab::Email::ProjectNotFound,
          Gitlab::Email::EmptyEmailError,
          Gitlab::Email::UserNotFoundError,
          Gitlab::Email::UserBlockedError,
          Gitlab::Email::UserNotAuthorizedError,
          Gitlab::Email::NoteableNotFoundError,
          Gitlab::Email::InvalidAttachment,
          Gitlab::Email::InvalidRecordError,
          Gitlab::Email::EmailTooLarge
        ]
      end

      with_them do
        it_behaves_like 'failed receive without event'
      end
    end

    describe 'handling errors which do raise events' do
      where(:expected_error) do
        [Gitlab::Email::EmailUnparsableError, Gitlab::Email::UnknownIncomingEmail, ArgumentError, StandardError]
      end

      with_them do
        it_behaves_like 'failed receive with event'
      end
    end
  end

  context "when the received field is malformed" do
    let(:email_raw) do
      attack = "for <<" * 100_000
      [
        "Delivered-To: incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com",
        "Received: from mail.example.com #{attack}; Thu, 13 Jun 2013 17:03:50 -0400",
        "To: \"support@example.com\" <support@example.com>",
        "",
        "Email content"
      ].join("\n")
    end

    it 'mail_metadata has no ReDos issue' do
      Timeout.timeout(2) do
        Gitlab::Email::Receiver.new(email_raw).mail_metadata
      end
    end
  end

  it 'requires all handlers to have a unique metric_event' do
    events = Gitlab::Email::Handler.handlers.map do |handler|
      handler.new(Mail::Message.new, 'gitlabhq/gitlabhq+auth_token').metrics_event
    end

    expect(events.uniq.count).to eq events.count
  end

  it 'requires all handlers to respond to #project' do
    Gitlab::Email::Handler.load_handlers.each do |handler|
      expect { handler.new(nil, nil).project }.not_to raise_error
    end
  end
end
