# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Utils::Email, feature_category: :service_desk do
  using RSpec::Parameterized::TableSyntax

  describe '.obfuscated_email' do
    where(:input, :output) do
      'alex@gitlab.com'                                | 'al**@g*****.com'
      'alex@gl.co.uk'                                  | 'al**@g****.uk'
      'a@b.c'                                          | 'aa@b.c'
      'qqwweerrttyy@example.com'                       | 'qq**********@e******.com'
      'getsuperfancysupport@paywhatyouwant.accounting' | 'ge******************@p*************.accounting'
      'q@example.com'                                  | 'qq@e******.com'
      'q@w.'                                           | 'qq@w.'
      'a@b'                                            | 'aa@b'
      'trun"@"e@example.com'                           | 'tr******@e******.com'
      '@'                                              | '@'
      'n'                                              | 'n'
      'no mail'                                        | 'n******'
      'truncated@exa'                                  | 'tr*******@exa'
      ''                                               | ''
    end

    with_them do
      it { expect(described_class.obfuscated_email(input)).to eq(output) }
    end

    context 'when deform is active' do
      where(:input, :output) do
        'alex@gitlab.com'                                | 'al*****@g*****.c**'
        'alex@gl.co.uk'                                  | 'al*****@g*****.u**'
        'a@b.c'                                          | 'aa*****@b*****.c**'
        'qqwweerrttyy@example.com'                       | 'qq*****@e*****.c**'
        'getsuperfancysupport@paywhatyouwant.accounting' | 'ge*****@p*****.a**'
        'q@example.com'                                  | 'qq*****@e*****.c**'
        'q@w.'                                           | 'qq*****@w*****.'
        'a@b'                                            | 'aa*****@b**'
        'trun"@"e@example.com'                           | 'tr*****@e*****.c**'
        '@'                                              | '@'
        'no mail'                                        | 'n**'
        'n'                                              | 'n**'
        'truncated@exa'                                  | 'tr*****@e**'
        ''                                               | ''
      end

      with_them do
        it { expect(described_class.obfuscated_email(input, deform: true)).to eq(output) }
      end
    end
  end

  describe '.obfuscate_emails_in_text' do
    where(:input, :output) do
      nil | nil
      '' | ''
      'added no email address' | 'added no email address'
      'added user@example.com' | 'added us*****@e*****.c**'
      'added user@example.com and hello@example.com' | 'added us*****@e*****.c** and he*****@e*****.c**'
      'removed user@example.com, hello@example.com and bye@example.com' |
        'removed us*****@e*****.c**, he*****@e*****.c** and by*****@e*****.c**'
      'added user#@example.com, hello!@example.com and bye$@example.com' |
        'added us*****@e*****.c**, he*****@e*****.c** and by*****@e*****.c**'
      'added user_@example.com, hello}@example.com and !#$%&\'*+-/=?^_{|}~@example.com' |
        'added us*****@e*****.c**, he*****@e*****.c** and !#*****@e*****.c**'
    end

    with_them do
      it { expect(described_class.obfuscate_emails_in_text(input)).to eq(output) }
    end
  end

  describe "#normalize_email" do
    subject { described_class.normalize_email(raw_email) }

    using RSpec::Parameterized::TableSyntax

    where(:raw_email, :expected_result) do
      nil                     | nil
      'notanemail@'           | 'notanemail@'
      '@notanemail.com'       | '@notanemail.com'
      'NotAnEmail'            | 'NotAnEmail'
      'USER@example.com'      | 'user@example.com'
      'u.s.e.r@example.com'   | 'u.s.e.r@example.com'
      'user+123@example.com'  | 'user@example.com'
      'us.er+123@example.com' | 'us.er@example.com'
      'u.s.e.r@gmail.com'     | 'user@gmail.com'
      'user+123@gmail.com'    | 'user@gmail.com'
      'us.er+123@gmail.com'   | 'user@gmail.com'
      ' us.er+123@gmail.com ' | 'user@gmail.com'
    end

    with_them do
      it { is_expected.to eq expected_result }
    end
  end
end
