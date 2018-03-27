require 'spec_helper'

describe WebHookService do
  let(:project) { create(:project) }
  let(:project_hook) { create(:project_hook) }
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'X-Gitlab-Event' => 'Push Hook'
    }
  end
  let(:data) do
    { before: 'oldrev', after: 'newrev', ref: 'ref' }
  end
  let(:service_instance) { described_class.new(project_hook, data, :push_hooks) }

  describe '#initialize' do
    it 'allow_local_requests is true if hook is a SystemHook' do
      instance = described_class.new(build(:system_hook), data, :system_hook)
      expect(instance.request_options[:allow_local_requests]).to be_truthy
    end

    it 'allow_local_requests is false if hook is not a SystemHook' do
      %i(project_hook service_hook web_hook_log).each do |hook|
        instance = described_class.new(build(hook), data, hook)
        expect(instance.request_options[:allow_local_requests]).to be_falsey
      end
    end
  end

  describe '#execute' do
    before do
      project.hooks << [project_hook]

      WebMock.stub_request(:post, project_hook.url)
    end

    context 'when token is defined' do
      let(:project_hook) { create(:project_hook, :token) }

      it 'POSTs to the webhook URL' do
        service_instance.execute
        expect(WebMock).to have_requested(:post, project_hook.url).with(
          headers: headers.merge({ 'X-Gitlab-Token' => project_hook.token })
        ).once
      end
    end

    it 'POSTs to the webhook URL' do
      service_instance.execute
      expect(WebMock).to have_requested(:post, project_hook.url).with(
        headers: headers
      ).once
    end

    it 'POSTs the data as JSON' do
      service_instance.execute
      expect(WebMock).to have_requested(:post, project_hook.url).with(
        headers: headers
      ).once
    end

    it 'catches exceptions' do
      WebMock.stub_request(:post, project_hook.url).to_raise(StandardError.new('Some error'))

      expect { service_instance.execute }.to raise_error(StandardError)
    end

    it 'handles exceptions' do
      exceptions = [SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout]
      exceptions.each do |exception_class|
        exception = exception_class.new('Exception message')

        WebMock.stub_request(:post, project_hook.url).to_raise(exception)
        expect(service_instance.execute).to eq({ status: :error, message: exception.message })
        expect { service_instance.execute }.not_to raise_error
      end
    end

    it 'handles 200 status code' do
      WebMock.stub_request(:post, project_hook.url).to_return(status: 200, body: 'Success')

      expect(service_instance.execute).to include({ status: :success, http_status: 200, message: 'Success' })
    end

    it 'handles 2xx status codes' do
      WebMock.stub_request(:post, project_hook.url).to_return(status: 201, body: 'Success')

      expect(service_instance.execute).to include({ status: :success, http_status: 201, message: 'Success' })
    end

    context 'execution logging' do
      let(:hook_log) { project_hook.web_hook_logs.last }

      context 'with success' do
        before do
          WebMock.stub_request(:post, project_hook.url).to_return(status: 200, body: 'Success')
          service_instance.execute
        end

        it 'log successful execution' do
          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('Success')
          expect(hook_log.response_status).to eq('200')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to be_nil
        end
      end

      context 'with exception' do
        before do
          WebMock.stub_request(:post, project_hook.url).to_raise(SocketError.new('Some HTTP Post error'))
          service_instance.execute
        end

        it 'log failed execution' do
          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('')
          expect(hook_log.response_status).to eq('internal error')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to eq('Some HTTP Post error')
        end
      end

      context 'with unsafe response body' do
        before do
          WebMock.stub_request(:post, project_hook.url).to_return(status: 200, body: "\xBB")
          service_instance.execute
        end

        it 'log successful execution' do
          expect(hook_log.trigger).to eq('push_hooks')
          expect(hook_log.url).to eq(project_hook.url)
          expect(hook_log.request_headers).to eq(headers)
          expect(hook_log.response_body).to eq('')
          expect(hook_log.response_status).to eq('200')
          expect(hook_log.execution_duration).to be > 0
          expect(hook_log.internal_error_message).to be_nil
        end
      end

      context 'should not log ServiceHooks' do
        let(:service_hook) { create(:service_hook) }
        let(:service_instance) { described_class.new(service_hook, data, 'service_hook') }

        before do
          WebMock.stub_request(:post, service_hook.url).to_return(status: 200, body: 'Success')
        end

        it { expect { service_instance.execute }.not_to change(WebHookLog, :count) }
      end
    end
  end

  describe '#async_execute' do
    let(:system_hook) { create(:system_hook) }

    it 'enqueue WebHookWorker' do
      expect(WebHookWorker).to receive(:perform_async).with(project_hook.id, data, 'push_hooks')

      described_class.new(project_hook, data, 'push_hooks').async_execute
    end
  end
end
