# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Receiver, feature_category: :shared do
  include_context 'email shared context'

  let_it_be_with_reload(:project) { create(:project) }

  let(:metric_transaction) { instance_double(Gitlab::Metrics::WebTransaction, increment: true, observe: true) }
  let(:mail_key) { 'gitlabhq/gitlabhq+auth_token' }

  shared_examples 'successful receive' do
    let(:handler) { double(:handler, project: project, execute: true, metrics_event: nil, metrics_params: nil) }
    let(:client_id) { 'email/jake@example.com' }

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

      expect(metadata.keys).to match_array(%i[mail_uid from_address to_address mail_key references delivered_to envelope_to x_envelope_to meta received_recipients cc_address x_original_to x_forwarded_to x_delivered_to])
      expect(metadata[:meta]).to include(client_id: client_id, project: project.full_path)
      expect(metadata[meta_key]).to eq(meta_value)
    end
  end

  shared_examples 'failed receive with event' do
    it 'adds metric event' do
      # Use allow here because we receive it multiple times which is out of scope of this class
      allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)

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
    let(:incoming_email) { "incoming+gitlabhq/gitlabhq+auth_token@appmail.example.com" }
    let(:meta_value) { [incoming_email] }

    before do
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.example.com")
    end

    context 'when in a Delivered-To header' do
      let(:email_raw) { fixture_file('emails/forwarded_new_issue.eml') }
      let(:meta_key) { :delivered_to }
      let(:meta_value) { [incoming_email, "support@example.com"] }

      it_behaves_like 'successful receive'
    end

    context 'when in an Envelope-To header' do
      let(:email_raw) { fixture_file('emails/envelope_to_header.eml') }
      let(:meta_key) { :envelope_to }

      it_behaves_like 'successful receive'
    end

    context 'when in an X-Envelope-To header' do
      let(:email_raw) { fixture_file('emails/x_envelope_to_header.eml') }
      let(:meta_key) { :x_envelope_to }

      it_behaves_like 'successful receive'
    end

    context 'when enclosed with angle brackets in an Envelope-To header' do
      let(:email_raw) { fixture_file('emails/envelope_to_header_with_angle_brackets.eml') }
      let(:meta_key) { :envelope_to }
      let(:meta_value) { ["<#{incoming_email}>"] }

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
      let(:meta_value) { [incoming_email, 'incoming+gitlabhq/gitlabhq@example.com'] }

      describe 'it uses receive headers to find the key' do
        it_behaves_like 'successful receive'
      end
    end

    context 'when in a Cc header' do
      let(:email_raw) do
        <<~EMAIL
        From: jake@example.com
        To: to@example.com
        Cc: #{incoming_email}
        Subject: Issue titile

        Issue description
        EMAIL
      end

      let(:meta_key) { :cc_address }

      it_behaves_like 'successful receive'
    end

    context 'when in a X-Original-To header' do
      let(:email_raw) do
        <<~EMAIL
        From: jake@example.com
        To: to@example.com
        X-Original-To: #{incoming_email}
        Subject: Issue titile

        Issue description
        EMAIL
      end

      let(:meta_key) { :x_original_to }

      it_behaves_like 'successful receive'
    end

    context 'when in a X-Forwarded-To header' do
      let(:email_raw) do
        <<~EMAIL
        From: jake@example.com
        To: to@example.com
        X-Forwarded-To: #{incoming_email}
        Subject: Issue titile

        Issue description
        EMAIL
      end

      let(:meta_key) { :x_forwarded_to }

      it_behaves_like 'successful receive'
    end

    context 'when in a X-Delivered-To header' do
      let(:email_raw) do
        <<~EMAIL
        From: jake@example.com
        To: to@example.com
        X-Delivered-To: #{incoming_email}
        Subject: Issue titile

        Issue description
        EMAIL
      end

      let(:meta_key) { :x_delivered_to }

      it_behaves_like 'successful receive'
    end

    context 'for Service Desk custom email' do
      let_it_be_with_refind(:setting) { create(:service_desk_setting, project: project, add_external_participants_from_cc: true) }

      let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
      let!(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }

      let(:incoming_email) { ::ServiceDesk::Emails.new(project).send(:incoming_address) }
      let(:mail_key) { "5de1a83a6fc3c9fe34d756c7f484159e" }
      let(:email) { "support+#{mail_key}@example.com" }
      let(:meta_key) { :to_address }
      let(:meta_value) { [email] }

      shared_examples 'successful receive from Delivered-To header' do
        context 'when in Delivered-To header' do
          let(:email_raw) do
            <<~EMAIL
            Delivered-To: #{incoming_email}
            From: jake@example.com
            To: #{email}
            Subject: Title

            Reply body
            EMAIL
          end

          it_behaves_like 'successful receive'
        end
      end

      shared_examples 'successful receive from To header' do
        context 'when in To header' do
          let(:email_raw) do
            <<~EMAIL
            From: jake@example.com
            To: #{email}
            Subject: Title

            Reply body
            EMAIL
          end

          it_behaves_like 'successful receive'

          context 'when also incoming address is in To header' do
            let(:email_raw) do
              <<~EMAIL
              From: jake@example.com
              To: #{email}, #{incoming_email}
              Subject: Title

              Body
              EMAIL
            end

            let(:meta_value) { [email, incoming_email] }

            it_behaves_like 'successful receive'
          end
        end
      end

      before do
        # Technically the state of ServiceDeskSetting and custom email records differ based on
        # the verification state and whether it's enabled or not.
        # But we always want to match a custom email with a project key and decide
        # to discard that email later in the handler.
        # So we ignore the custom email state here for simplicity.
        setting.update!(custom_email: 'support@example.com', custom_email_enabled: true)
        project.reset
      end

      context 'for email to custom email address with reply key' do
        it_behaves_like 'successful receive from Delivered-To header'
        it_behaves_like 'successful receive from To header'
      end

      context 'for verification email' do
        let(:mail_key) { ::ServiceDesk::Emails.new(project).default_subaddress_part }
        let(:email) { "support+verify@example.com" }

        it_behaves_like 'successful receive from Delivered-To header'
        it_behaves_like 'successful receive from To header'
      end

      context 'for email to custom email address' do
        let(:mail_key) { ::ServiceDesk::Emails.new(project).default_subaddress_part }
        let(:email) { "support@example.com" }

        it_behaves_like 'successful receive from Delivered-To header'
        it_behaves_like 'successful receive from To header'
      end
    end
  end

  context 'when we cannot find a capable handler' do
    let(:expected_error) { Gitlab::Email::UnknownIncomingEmail }

    context 'when mail key is not correct' do
      let(:email_raw) do
        <<~EMAIL
        From: from@example.com
        To: incoming+!!!@example.com
        In-Reply-To: <issue_1@localhost>
        References: <incoming-!!!@localhost> <issue_1@localhost>
        Subject: Title

        Body
        EMAIL
      end

      it_behaves_like 'failed receive with event'
    end

    context 'when email is not known' do
      let(:email_raw) do
        <<~EMAIL
        From: from@example.com
        To: to@example.com
        Subject: Title

        Body
        EMAIL
      end

      it_behaves_like 'failed receive with event'
    end
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
