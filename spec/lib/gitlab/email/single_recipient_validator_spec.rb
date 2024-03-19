# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Email::SingleRecipientValidator, feature_category: :system_access do
  let(:receiver) { Class.new.include(described_class).new }

  describe '#validate_single_recipient_in_opts!' do
    subject(:call) { receiver.validate_single_recipient_in_opts!(opts) }

    context 'with no or a single recipient' do
      where(:opts) do
        [
          { to: nil },
          { to: "" },
          { to: "", cc: nil, bcc: nil },
          { to: "invalidemail" },
          { to: "foo@example.com" }
        ]
      end

      with_them do
        it 'returns true', :aggregate_failures do
          expect(call).to be true
        end
      end
    end

    context 'with invalid opts' do
      where(:opts) do
        [
          { cc: "" },
          { bcc: "   " },
          { bcc: "foo@example.com" },
          { cc: ["foo@example.com", "bar@example.com"] },
          { cc: [] },
          { to: "foo", "to" => "bar" },
          # The following are duplicative of #validate_single_recipient_in_email specs
          { to: "foo@example.com,bar@example.com" },
          { to: "foo@example.com;bar@example.com" },
          { to: ["foo@example.com", "bar@example.com"] }
        ]
      end

      with_them do
        it 'raises', :aggregate_failures do
          expect { call }.to raise_error(Gitlab::Email::MultipleRecipientsError)
        end
      end
    end
  end

  describe '#validate_single_recipient_in_email' do
    subject(:call) { receiver.validate_single_recipient_in_email(email) }

    where(:email, :expected_value) do
      [
        [["foo@example.com", "bar@example.com"], false],
        [{ foo: "bar" }, false],
        ['foo@example.com,bar@example.com', false],
        ['foo@example.com;bar@example.com', false],
        ['foo@example.com;', false],
        [',', false],
        [';', false],
        ['foo@example.com', true],
        ['foo@example.com bar@example.com', true]
      ]
    end

    with_them do
      it 'returns the expected value', :aggregate_failures do
        expect(call).to eq(expected_value)
      end
    end
  end

  describe '#validate_single_recipient_in_email!' do
    it 'raises an error for multiple recipients', :aggregate_failures do
      expect do
        receiver.validate_single_recipient_in_email!(',')
      end.to raise_error(Gitlab::Email::MultipleRecipientsError)
    end

    it 'raises nothing for single recipient', :aggregate_failures do
      expect do
        receiver.validate_single_recipient_in_email!('foo')
      end.not_to raise_error
    end
  end
end
