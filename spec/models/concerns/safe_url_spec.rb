# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeUrl do
  describe '#safe_url' do
    let(:safe_url_test_class) do
      Class.new do
        include SafeUrl

        attr_reader :url

        def initialize(url)
          @url = url
        end
      end
    end

    let(:test_class) { safe_url_test_class.new(url) }
    let(:url) { 'http://example.com' }

    subject { test_class.safe_url }

    it { is_expected.to eq(url) }

    context 'when URL contains credentials' do
      let(:url) { 'http://foo:bar@example.com' }

      it 'masks username and password' do
        is_expected.to eq('http://*****:*****@example.com')
      end

      context 'when username is allowed' do
        subject { test_class.safe_url(allowed_usernames: usernames) }

        let(:usernames) { %w[foo] }

        it 'masks the password, but not the username' do
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
