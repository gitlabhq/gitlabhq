# frozen_string_literal: true

require 'fast_spec_helper'

MAIL_ROOM_CONFIG_ENABLED_SAMPLE =
  ":mailboxes:\n"\
  "  \n"\
  "    -\n"\
  "      :host: \"gitlab.example.com\"\n"\
  "      :port: 143\n"\
  ""

RSpec.describe SystemCheck::IncomingEmail::ImapAuthenticationCheck do
  subject(:system_check) { described_class.new }

  describe '#load_config' do
    subject { system_check.send(:load_config) }

    context 'returns no mailbox configurations with mailroom default configuration' do
      it { is_expected.to be_nil }
    end

    context 'returns an array of mailbox configurations with mailroom configured' do
      before do
        allow(File).to receive(:read).and_return(MAIL_ROOM_CONFIG_ENABLED_SAMPLE)
      end

      it { is_expected.to eq([{ host: "gitlab.example.com", port: 143 }]) }
    end
  end
end
