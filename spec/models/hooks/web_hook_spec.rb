require 'spec_helper'

describe WebHook do
  let(:hook) { build(:project_hook) }

  describe 'associations' do
    it { is_expected.to have_many(:web_hook_logs).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:url) }

    describe 'url' do
      it { is_expected.to allow_value('http://example.com').for(:url) }
      it { is_expected.to allow_value('https://example.com').for(:url) }
      it { is_expected.to allow_value(' https://example.com ').for(:url) }
      it { is_expected.to allow_value('http://test.com/api').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc&type=def').for(:url) }

      it { is_expected.not_to allow_value('example.com').for(:url) }
      it { is_expected.not_to allow_value('ftp://example.com').for(:url) }
      it { is_expected.not_to allow_value('herp-and-derp').for(:url) }

      it 'strips :url before saving it' do
        hook.url = ' https://example.com '
        hook.save

        expect(hook.url).to eq('https://example.com')
      end
    end

    describe 'token' do
      it { is_expected.to allow_value("foobar").for(:token) }

      it { is_expected.not_to allow_values("foo\nbar", "foo\r\nbar").for(:token) }
    end
  end

  describe 'execute' do
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'project hook' }

    before do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name).and_call_original
    end

    it '#execute' do
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it '#async_execute' do
      expect_any_instance_of(WebHookService).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end
  end
end
