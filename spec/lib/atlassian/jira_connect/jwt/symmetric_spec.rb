# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Jwt::Symmetric, feature_category: :integrations do
  let(:shared_secret) { 'secret' }

  describe '#iss_claim' do
    let(:jwt) { Atlassian::Jwt.encode({ iss: '123' }, shared_secret) }

    subject { described_class.new(jwt).iss_claim }

    it { is_expected.to eq('123') }

    context 'invalid JWT' do
      let(:jwt) { '123' }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#sub_claim' do
    let(:jwt) { Atlassian::Jwt.encode({ sub: '123' }, shared_secret) }

    subject { described_class.new(jwt).sub_claim }

    it { is_expected.to eq('123') }

    context 'invalid JWT' do
      let(:jwt) { '123' }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#valid?' do
    subject { described_class.new(jwt).valid?(shared_secret) }

    context 'invalid JWT' do
      let(:jwt) { '123' }

      it { is_expected.to eq(false) }
    end

    context 'valid JWT' do
      let(:jwt) { Atlassian::Jwt.encode({}, shared_secret) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#verify_qsh_claim' do
    let(:jwt) { Atlassian::Jwt.encode({ qsh: qsh_claim }, shared_secret) }
    let(:qsh_claim) do
      Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test')
    end

    subject(:verify_qsh_claim) do
      described_class.new(jwt).verify_qsh_claim('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test')
    end

    it { is_expected.to eq(true) }

    context 'qsh does not match' do
      let(:qsh_claim) do
        Atlassian::Jwt.create_query_string_hash('https://example.com/foo', 'POST', 'https://example.com')
      end

      it { is_expected.to eq(false) }
    end

    context 'creating query string hash raises an error' do
      let(:qsh_claim) { '123' }

      specify do
        expect(Atlassian::Jwt).to receive(:create_query_string_hash).and_raise(StandardError)

        expect(verify_qsh_claim).to eq(false)
      end
    end
  end

  describe '#verify_context_qsh_claim' do
    let(:jwt) { Atlassian::Jwt.encode({ qsh: qsh_claim }, shared_secret) }
    let(:qsh_claim) { 'context-qsh' }

    subject(:verify_context_qsh_claim) { described_class.new(jwt).verify_context_qsh_claim }

    it { is_expected.to eq(true) }

    context 'jwt does not contain a context qsh' do
      let(:qsh_claim) { '123' }

      it { is_expected.to eq(false) }
    end
  end
end
