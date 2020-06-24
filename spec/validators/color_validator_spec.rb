# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ColorValidator do
  using RSpec::Parameterized::TableSyntax

  subject do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :color
      validates :color, color: true
    end.new
  end

  where(:color, :is_valid) do
    '#000abc'    | true
    '#aaa'       | true
    '#BBB'       | true
    '#cCc'       | true
    '#ffff'      | false
    '#000111222' | false
    'invalid'    | false
    '000'        | false
  end

  with_them do
    it 'only accepts valid colors' do
      subject.color = color

      expect(subject.valid?).to eq(is_valid)
    end
  end

  it 'fails fast for long invalid string' do
    subject.color = '#' + ('0' * 50_000) + 'xxx'

    expect do
      Timeout.timeout(5.seconds) { subject.valid? }
    end.not_to raise_error
  end
end
