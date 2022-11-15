# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Packagist do
  it_behaves_like Integrations::HasWebHook do
    let_it_be(:project) { create(:project) }

    let(:integration) { build(:packagist_integration, project: project) }
    let(:hook_url) { "#{integration.server}/api/update-package?username={username}&apiToken={token}" }
  end

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { build(:packagist_integration) }
  end

  describe '#execute' do
    let(:project) { build(:project) }
    let(:integration) { build(:packagist_integration, project: project) }

    let(:packagist_hook_url) do
      "#{integration.server}/api/update-package?username=#{integration.username}&apiToken=#{integration.token}"
    end

    before do
      stub_request(:post, packagist_hook_url)
    end

    it 'calls Packagist API' do
      user = create(:user)
      push_sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      integration.execute(push_sample_data)

      expect(a_request(:post, packagist_hook_url)).to have_been_made.once
    end
  end

  describe '#test' do
    let(:integration) { build(:packagist_integration) }
    let(:test_data) { { foo: 'bar' } }

    subject(:result) { integration.test(test_data) }

    context 'when test request executes without errors' do
      before do
        allow(integration).to receive(:execute).with(test_data).and_return(
          ServiceResponse.success(message: 'success message', payload: { http_status: http_status })
        )
      end

      context 'when response is a 200' do
        let(:http_status) { 200 }

        it 'return failure result' do
          is_expected.to eq(success: false, result: 'success message')
        end
      end

      context 'when response is a 202' do
        let(:http_status) { 202 }

        it 'return success result' do
          is_expected.to eq(success: true, result: 'success message')
        end
      end
    end

    context 'when test request executes with errors' do
      before do
        allow(integration).to receive(:execute).with(test_data).and_raise(StandardError, 'error message')
      end

      it 'return failure result' do
        is_expected.to eq(success: false, result: 'error message')
      end
    end
  end
end
