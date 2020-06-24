# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHook do
  let(:hook) { build(:project_hook) }

  describe 'associations' do
    it { is_expected.to have_many(:web_hook_logs) }
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

    describe 'push_events_branch_filter' do
      it { is_expected.to allow_values("good_branch_name", "another/good-branch_name").for(:push_events_branch_filter) }
      it { is_expected.to allow_values("").for(:push_events_branch_filter) }
      it { is_expected.not_to allow_values("bad branch name", "bad~branchname").for(:push_events_branch_filter) }

      it 'gets rid of whitespace' do
        hook.push_events_branch_filter = ' branch '
        hook.save

        expect(hook.push_events_branch_filter).to eq('branch')
      end

      it 'stores whitespace only as empty' do
        hook.push_events_branch_filter = ' '
        hook.save

        expect(hook.push_events_branch_filter).to eq('')
      end
    end
  end

  describe 'encrypted attributes' do
    subject { described_class.encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:token, :url) }
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

  describe '#destroy' do
    it 'cascades to web_hook_logs' do
      web_hook = create(:project_hook)
      create_list(:web_hook_log, 3, web_hook: web_hook)

      expect { web_hook.destroy }.to change(web_hook.web_hook_logs, :count).by(-3)
    end
  end
end
