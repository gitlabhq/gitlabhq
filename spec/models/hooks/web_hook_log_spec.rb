# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookLog, feature_category: :webhooks do
  it { is_expected.to belong_to(:web_hook) }

  it { is_expected.to serialize(:request_headers).as(Hash) }
  it { is_expected.to serialize(:request_data).as(Hash) }
  it { is_expected.to serialize(:response_headers).as(Hash) }

  it { is_expected.to validate_presence_of(:web_hook) }

  describe '.recent' do
    let(:hook) { build(:project_hook) }

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
    let(:hook) { build(:project_hook) }

    context 'with basic auth credentials' do
      let(:web_hook_log) { build(:web_hook_log, web_hook: hook, url: 'http://test:123@example.com') }

      subject { web_hook_log.save! }

      it { is_expected.to eq(true) }

      it 'obfuscates the basic auth credentials' do
        subject

        expect(web_hook_log.url).to eq('http://*****:*****@example.com')
      end
    end

    context 'with basic auth credentials and masked components' do
      let(:web_hook_log) { build(:web_hook_log, web_hook: hook, url: 'http://test:123@{domain}.com:{port}') }

      subject { web_hook_log.save! }

      it { is_expected.to eq(true) }

      it 'obfuscates the basic auth credentials' do
        subject

        expect(web_hook_log.url).to eq('http://*****:*****@{domain}.com:{port}')
      end
    end

    context "with users' emails" do
      let(:author) { build(:user) }
      let(:user) { build(:user) }
      let(:web_hook_log) { create(:web_hook_log, web_hook: hook, request_data: data) }
      let(:data) do
        {
          user: {
            name: user.name,
            email: user.email
          },
          commits: [
            {
              user: {
                name: author.name,
                email: author.email
              }
            },
            {
              user: {
                name: user.name,
                email: user.email
              }
            }
          ]
        }.deep_stringify_keys
      end

      it "redacts users' emails" do
        expect(web_hook_log.request_data['user']).to match a_hash_including(
          'name' => user.name,
          'email' => _('[REDACTED]')
        )
        expect(web_hook_log.request_data['commits'].pluck('user')).to match_array(
          [
            {
              'name' => author.name,
              'email' => _('[REDACTED]')
            },
            {
              'name' => user.name,
              'email' => _('[REDACTED]')
            }
          ]
        )
      end
    end
  end

  describe 'before_save' do
    describe '#set_url_hash' do
      let(:web_hook_log) { build(:web_hook_log, interpolated_url: interpolated_url) }

      subject(:save_web_hook_log) { web_hook_log.save! }

      context 'when interpolated_url is nil' do
        let(:interpolated_url) { nil }

        it { expect { save_web_hook_log }.not_to change { web_hook_log.url_hash } }
      end

      context 'when interpolated_url has a blank value' do
        let(:interpolated_url) { ' ' }

        it { expect { save_web_hook_log }.not_to change { web_hook_log.url_hash } }
      end

      context 'when interpolated_url has a value' do
        let(:interpolated_url) { 'example@gitlab.com' }
        let(:expected_value) { Gitlab::CryptoHelper.sha256(interpolated_url) }

        it 'assigns correct digest value' do
          expect { save_web_hook_log }.to change { web_hook_log.url_hash }.from(nil).to(expected_value)
        end
      end
    end
  end

  describe '.delete_batch_for' do
    let_it_be(:hook) { build(:project_hook) }
    let_it_be(:hook2) { build(:project_hook) }

    before_all do
      create_list(:web_hook_log, 3, web_hook: hook)
      create_list(:web_hook_log, 3, web_hook: hook2)
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

  describe '#request_headers' do
    let(:web_hook_log) { build(:web_hook_log, request_headers: request_headers) }
    let(:expected_headers) { { 'X-Gitlab-Token' => _('[REDACTED]') } }

    context 'with redacted headers token' do
      let(:request_headers) { { 'X-Gitlab-Token' => _('[REDACTED]') } }

      it { expect(web_hook_log.request_headers).to eq(expected_headers) }
    end

    context 'with exposed headers token' do
      let(:request_headers) { { 'X-Gitlab-Token' => 'secret_token' } }

      it { expect(web_hook_log.request_headers).to eq(expected_headers) }
    end

    context 'with no token headers' do
      let(:request_headers) { {} }

      it { expect(web_hook_log.request_headers['X-Gitlab-Token']).to be_nil }
    end
  end

  describe '#url_current?' do
    let(:url) { 'example@gitlab.com' }

    let(:hook) { build(:project_hook, url: url) }
    let(:web_hook_log) do
      build(
        :web_hook_log,
        web_hook: hook,
        interpolated_url: hook.url,
        url_hash: Gitlab::CryptoHelper.sha256('example@gitlab.com')
      )
    end

    context 'with matching url' do
      it { expect(web_hook_log.url_current?).to be_truthy }
    end

    context 'with different url' do
      let(:url) { 'example@gitlab2.com' }

      it { expect(web_hook_log.url_current?).to be_falsey }
    end
  end

  describe 'Scopes' do
    describe '.by_status_code' do
      it 'returns web hook logs with status code 200' do
        log_200 = create(:web_hook_log)
        create(:web_hook_log, response_status: 400)
        create(:web_hook_log, response_status: 500)

        expect(described_class.by_status_code(200)).to match_array([log_200])
      end
    end
  end
end
