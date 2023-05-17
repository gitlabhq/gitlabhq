# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SquashTm, feature_category: :integrations do
  it_behaves_like Integrations::HasWebHook do
    let_it_be(:project) { create(:project) }

    let(:integration) { build(:squash_tm_integration, project: project) }
    let(:hook_url) { "#{integration.url}?token={token}" }
  end

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { subject }
  end

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to allow_value('https://example.com').for(:url) }
      it { is_expected.not_to allow_value(nil).for(:url) }
      it { is_expected.not_to allow_value('').for(:url) }
      it { is_expected.not_to allow_value('foo').for(:url) }
      it { is_expected.not_to allow_value('example.com').for(:url) }

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.to validate_length_of(:token).is_at_most(255) }
      it { is_expected.to allow_value(nil).for(:token) }
      it { is_expected.to allow_value('foo').for(:token) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe '#execute' do
    let(:integration) { build(:squash_tm_integration, project: build(:project)) }

    let(:squash_tm_hook_url) do
      "#{integration.url}?token=#{integration.token}"
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let(:data) { issue.to_hook_data(user) }

    before do
      stub_request(:post, squash_tm_hook_url)
    end

    it 'calls Squash TM API' do
      integration.execute(data)

      expect(a_request(:post, squash_tm_hook_url)).to have_been_made.once
    end
  end

  describe '#test' do
    let(:integration) { build(:squash_tm_integration) }

    let(:squash_tm_hook_url) do
      "#{integration.url}?token=#{integration.token}"
    end

    subject(:result) { integration.test({}) }

    context 'when server is responding' do
      let(:body) { 'OK' }
      let(:status) { 200 }

      before do
        stub_request(:post, squash_tm_hook_url)
          .to_return(status: status, body: body)
      end

      it { is_expected.to eq(success: true, result: 'OK') }
    end

    context 'when server rejects the request' do
      let(:body) { 'Unauthorized' }
      let(:status) { 401 }

      before do
        stub_request(:post, squash_tm_hook_url)
          .to_return(status: status, body: body)
      end

      it { is_expected.to eq(success: false, result: body) }
    end

    context 'when test request executes with errors' do
      before do
        allow(integration).to receive(:execute_web_hook!)
          .with({}, "Test Configuration Hook")
          .and_raise(StandardError, 'error message')
      end

      it { is_expected.to eq(success: false, result: 'error message') }
    end
  end

  describe '.default_test_event' do
    subject { described_class.default_test_event }

    it { is_expected.to eq('issue') }
  end
end
