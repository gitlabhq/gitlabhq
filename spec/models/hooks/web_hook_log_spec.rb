# frozen_string_literal: true

require 'spec_helper'

describe WebHookLog do
  it { is_expected.to belong_to(:web_hook) }

  it { is_expected.to serialize(:request_headers).as(Hash) }
  it { is_expected.to serialize(:request_data).as(Hash) }
  it { is_expected.to serialize(:response_headers).as(Hash) }

  it { is_expected.to validate_presence_of(:web_hook) }

  describe '.recent' do
    let(:hook) { create(:project_hook) }

    it 'does not return web hook logs that are too old' do
      create(:web_hook_log, web_hook: hook, created_at: 91.days.ago)

      expect(described_class.recent.size).to be_zero
    end

    it 'returns the web hook logs in descending order' do
      hook1 = create(:web_hook_log, web_hook: hook, created_at: 2.hours.ago)
      hook2 = create(:web_hook_log, web_hook: hook, created_at: 1.hour.ago)
      hooks = described_class.recent.to_a

      expect(hooks).to eq([hook2, hook1])
    end
  end

  describe '#save' do
    let(:web_hook_log) { build(:web_hook_log, url: url) }
    let(:url) { 'http://example.com' }

    subject { web_hook_log.save! }

    it { is_expected.to eq(true) }

    context 'with basic auth credentials' do
      let(:url) { 'http://test:123@example.com'}

      it 'obfuscates the basic auth credentials' do
        subject

        expect(web_hook_log.url).to eq('http://*****:*****@example.com')
      end
    end
  end

  describe '#success?' do
    let(:web_hook_log) { build(:web_hook_log, response_status: status) }

    describe '2xx' do
      let(:status) { '200' }
      it { expect(web_hook_log.success?).to be_truthy }
    end

    describe 'not 2xx' do
      let(:status) { '500' }
      it { expect(web_hook_log.success?).to be_falsey }
    end

    describe 'internal erorr' do
      let(:status) { 'internal error' }
      it { expect(web_hook_log.success?).to be_falsey }
    end
  end
end
