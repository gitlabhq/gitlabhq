# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Utils::Email, feature_category: :service_desk do
  using RSpec::Parameterized::TableSyntax

  describe '.obfuscated_email' do
    where(:input, :output) do
      'alex@gitlab.com' | 'al**@g*****.com'
      'alex@gl.co.uk'   | 'al**@g****.uk'
      'a@b.c'           | 'a@b.c'
      'q@example.com'   | 'q@e******.com'
      'q@w.'            | 'q@w.'
      'a@b'             | 'a@b'
      'no mail'         | 'no mail'
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
        'q@w.'                                           | 'q@w.'
        'a@b'                                            | 'a@b'
        'no mail'                                        | 'no mail'
      end

      with_them do
        it { expect(described_class.obfuscated_email(input, deform: true)).to eq(output) }
      end
    end
  end
end
