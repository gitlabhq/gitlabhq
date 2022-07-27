# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookLog do
  it { is_expected.to belong_to(:web_hook) }

  it { is_expected.to serialize(:request_headers).as(Hash) }
  it { is_expected.to serialize(:request_data).as(Hash) }
  it { is_expected.to serialize(:response_headers).as(Hash) }

  it { is_expected.to validate_presence_of(:web_hook) }

  describe '.recent' do
    let(:hook) { create(:project_hook) }

    it 'does not return web hook logs that are too old' do
      create(:web_hook_log, web_hook: hook, created_at: 10.days.ago)

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
    context 'with basic auth credentials' do
      let(:web_hook_log) { build(:web_hook_log, url: 'http://test:123@example.com') }

      subject { web_hook_log.save! }

      it { is_expected.to eq(true) }

      it 'obfuscates the basic auth credentials' do
        subject

        expect(web_hook_log.url).to eq('http://*****:*****@example.com')
      end
    end

    context 'with author email' do
      let(:author) { create(:user) }
      let(:web_hook_log) { create(:web_hook_log, request_data: data) }
      let(:data) do
        {
          commit: {
            author: {
              name: author.name,
              email: author.email
            }
          }
        }.deep_stringify_keys
      end

      it "redacts author's email" do
        expect(web_hook_log.request_data['commit']).to match a_hash_including(
          'author' => {
            'name' => author.name,
            'email' => _('[REDACTED]')
          }
        )
      end
    end
  end

  describe '.delete_batch_for' do
    let(:hook) { create(:project_hook) }

    before do
      create_list(:web_hook_log, 3, web_hook: hook)
      create_list(:web_hook_log, 3)
    end

    subject { described_class.delete_batch_for(hook, batch_size: batch_size) }

    shared_examples 'deletes batch of web hook logs' do
      it { is_expected.to be(batch_size <= 3) }

      it 'deletes min(batch_size, total) records' do
        deleted = [batch_size, 3].min

        expect { subject }.to change(described_class, :count).by(-deleted)
      end
    end

    context 'when the batch size is less than one' do
      let(:batch_size) { 0 }

      it 'raises an argument error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when the batch size is smaller than the total' do
      let(:batch_size) { 2 }

      include_examples 'deletes batch of web hook logs'
    end

    context 'when the batch size is equal to the total' do
      let(:batch_size) { 3 }

      include_examples 'deletes batch of web hook logs'
    end

    context 'when the batch size is greater than the total' do
      let(:batch_size) { 1000 }

      include_examples 'deletes batch of web hook logs'
    end

    it 'does not loop forever' do
      batches = 0
      batches += 1 while described_class.delete_batch_for(hook, batch_size: 1)

      expect(hook.web_hook_logs).to be_none
      expect(described_class.count).to eq 3
      expect(batches).to eq 3 # true three times, stops at first false
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

  describe '#internal_error?' do
    let(:web_hook_log) { build_stubbed(:web_hook_log, response_status: status) }

    context 'when response status is not an internal error' do
      let(:status) { '200' }

      it { expect(web_hook_log.internal_error?).to be_falsey }
    end

    context 'when response status is an internal error' do
      let(:status) { 'internal error' }

      it { expect(web_hook_log.internal_error?).to be_truthy }
    end
  end
end
