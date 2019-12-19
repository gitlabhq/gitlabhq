# frozen_string_literal: true

require 'spec_helper'

describe SafeUrl do
  describe '#safe_url' do
    class SafeUrlTestClass
      include SafeUrl

      attr_reader :url

      def initialize(url)
        @url = url
      end
    end

    let(:test_class) { SafeUrlTestClass.new(url) }
    let(:url) { 'http://example.com' }

    subject { test_class.safe_url }

    it { is_expected.to eq(url) }

    context 'when URL contains credentials' do
      let(:url) { 'http://foo:bar@example.com' }

      it { is_expected.to eq('http://*****:*****@example.com')}

      context 'when username is whitelisted' do
        subject { test_class.safe_url(usernames_whitelist: usernames_whitelist) }

        let(:usernames_whitelist) { %w[foo] }

        it 'does expect the whitelisted username not to be masked' do
          is_expected.to eq('http://foo:*****@example.com')
        end
      end
    end

    context 'when URL is empty' do
      let(:url) { nil }

      it { is_expected.to be_nil }
    end

    context 'when URI raises an error' do
      let(:url) { 123 }

      it { is_expected.to be_nil }
    end
  end
end
