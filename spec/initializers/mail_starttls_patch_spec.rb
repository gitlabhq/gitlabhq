# frozen_string_literal: true

# rubocop:disable RSpec/VariableDefinition, RSpec/VariableName

require 'spec_helper'
require 'mail'
require_relative '../../config/initializers/mail_starttls_patch'

RSpec.describe 'Mail STARTTLS patch', feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:message) do
    Mail.new do
      from    'sender@example.com'
      to      'receiver@example.com'
      subject 'test mesage'
    end
  end

  # As long as this monkey patch exists and overrides the constructor
  # we should test that the defaults of Mail::SMTP are not overriden.
  #
  # @see issue https://gitlab.com/gitlab-org/gitlab/-/issues/423268
  # @see incident https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16223
  it 'does not override default constants values' do
    expected_settings = Mail::SMTP.new({}).settings.dup

    Mail.new.delivery_method(Mail::SMTP, { user_name: 'user@example.com' })

    expect(Mail::SMTP.new({}).settings).to eq(expected_settings)
  end

  describe 'enable_starttls_auto setting' do
    let(:settings) { {} }

    subject(:smtp) { Mail::SMTP.new(settings) }

    it 'uses default for enable_starttls_auto' do
      expect(smtp.settings).to include(enable_starttls_auto: nil)
    end

    context 'when set to false' do
      let(:settings) { { enable_starttls_auto: false } }

      it 'overrides default and sets value' do
        expect(smtp.settings).to include(enable_starttls_auto: false)
      end
    end
  end

  # Taken from https://github.com/mikel/mail/pull/1536#issue-1490438378
  where(:ssl, :tls, :enable_starttls, :enable_starttls_auto, :smtp_tls, :smtp_starttls_mode) do
    true  | nil   | nil     | nil   | true  | false
    nil   | false | nil     | nil   | false | :auto
    nil   | false | nil     | true  | false | :auto
    false | false | true    | false | false | :always
    false | nil   | false   | false | false | false
    false | false | false   | nil   | false | false
    false | nil   | :always | nil   | false | :always
    false | nil   | :auto   | nil   | false | :auto
  end

  with_them do
    let(:values) do
      {
        ssl: ssl,
        tls: tls,
        enable_starttls: enable_starttls,
        enable_starttls_auto: enable_starttls_auto
      }
    end

    let(:mail) { Mail::SMTP.new(values) }
    let(:smtp) { double }

    it 'sets TLS and STARTTLS settings properly' do
      expect(smtp).to receive(:open_timeout=)
      expect(smtp).to receive(:read_timeout=)
      expect(smtp).to receive(:start)

      if smtp_tls
        expect(smtp).to receive(:enable_tls)
        expect(smtp).to receive(:disable_starttls)
      else
        expect(smtp).to receive(:disable_tls)

        case smtp_starttls_mode
        when :always
          expect(smtp).to receive(:enable_starttls)
        when :auto
          expect(smtp).to receive(:enable_starttls_auto)
        when false
          expect(smtp).to receive(:disable_starttls)
        end
      end

      allow(Net::SMTP).to receive(:new).and_return(smtp)
      mail.deliver!(message)
    end
  end

  context 'when enable_starttls and tls are enabled' do
    let(:values) do
      {
        tls: true,
        enable_starttls: true
      }
    end

    let(:mail) { Mail::SMTP.new(values) }

    it 'raises an argument exception' do
      expect { mail.deliver!(message) }.to raise_error(ArgumentError)
    end
  end
end
# rubocop:enable RSpec/VariableDefinition, RSpec/VariableName
