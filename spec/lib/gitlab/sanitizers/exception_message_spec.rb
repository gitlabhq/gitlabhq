# frozen_string_literal: true

require 'fast_spec_helper'
require 'addressable'
require 'rspec-parameterized'

RSpec.describe Gitlab::Sanitizers::ExceptionMessage, feature_category: :compliance_management do
  describe '.clean' do
    let(:exception_name) { exception.class.name }
    let(:exception_message) { exception.message }

    subject { described_class.clean(exception_name, exception_message) }

    context 'when error is a URI::InvalidURIError' do
      let(:exception) do
        URI.parse('http://foo:bar')
      rescue URI::InvalidURIError => error
        error
      end

      it { is_expected.to eq('bad URI(is not URI?): [FILTERED]') }
    end

    context 'when error is an Addressable::URI::InvalidURIError' do
      using RSpec::Parameterized::TableSyntax

      let(:exception) do
        Addressable::URI.parse(uri)
      rescue Addressable::URI::InvalidURIError => error
        error
      end

      where(:uri, :result) do
        'http://foo:bar' | 'Invalid port number: [FILTERED]'
        'http://foo:%eb' | 'Invalid encoding in port'
        'ht%0atp://foo'  | 'Invalid scheme format: [FILTERED]'
        'http:'          | 'Absolute URI missing hierarchical segment: [FILTERED]'
        '::http'         | 'Cannot assemble URI string with ambiguous path: [FILTERED]'
        'http://foo bar' | 'Invalid character in host: [FILTERED]'
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'with any other exception' do
      let(:exception) { StandardError.new('Error message: http://foo@bar:baz@ex:ample.com') }

      it 'is not invoked and does nothing' do
        is_expected.to eq('Error message: http://foo@bar:baz@ex:ample.com')
      end
    end
  end
end
