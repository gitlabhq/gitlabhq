# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::AbuseValidators::NoAbusiveCoercionFromStringValidator do
  subject do
    described_class.new({ attributes: { foo: :bar } })
  end

  let(:instance) { double(:instance) }
  let(:attribute) { :attribute }
  let(:validation_msg) { 'abusive coercion from string detected' }
  let(:validate) { subject.validate_each(instance, attribute, attribute_value) }

  using ::RSpec::Parameterized::TableSyntax

  where(:attribute_value, :valid?) do
    ['this is an arry'] | false
    { this: 'is a hash' } | false
    123                     | false
    456.78                  | false
    'now this is a string'  | true
  end

  with_them do
    it do
      if valid?
        expect(instance).not_to receive(:errors)
      else
        expect(instance).to receive_message_chain(:errors, :add).with(attribute, validation_msg)
        validate
      end
    end
  end
end
