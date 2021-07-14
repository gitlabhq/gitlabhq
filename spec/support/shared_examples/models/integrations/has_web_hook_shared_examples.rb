# frozen_string_literal: true

RSpec.shared_examples Integrations::HasWebHook do
  include AfterNextHelpers

  describe 'callbacks' do
    it 'calls #update_web_hook! when enabled' do
      expect(integration).to receive(:update_web_hook!)

      integration.active = true
      integration.save!
    end

    it 'does not call #update_web_hook! when disabled' do
      expect(integration).not_to receive(:update_web_hook!)

      integration.active = false
      integration.save!
    end

    it 'does not call #update_web_hook! when validation fails' do
      expect(integration).not_to receive(:update_web_hook!)

      integration.active = true
      integration.project = nil
      expect(integration.save).to be(false)
    end
  end

  describe '#hook_url' do
    it 'returns a string' do
      expect(integration.hook_url).to be_a(String)
    end
  end

  describe '#hook_ssl_verification' do
    it 'returns a boolean' do
      expect(integration.hook_ssl_verification).to be_in([true, false])
    end
  end

  describe '#update_web_hook!' do
    def call
      integration.update_web_hook!
    end

    it 'creates or updates a service hook' do
      expect { call }.to change(ServiceHook, :count).by(1)
      expect(integration.service_hook.url).to eq(hook_url)

      integration.service_hook.update!(url: 'http://other.com')

      expect { call }.to change { integration.service_hook.reload.url }.from('http://other.com').to(hook_url)
    end

    it 'raises an error if the service hook could not be saved' do
      call
      integration.service_hook.integration = nil

      expect { call }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not attempt to save the service hook if there are no changes' do
      call

      expect(integration.service_hook).not_to receive(:save!)

      call
    end
  end

  describe '#execute_web_hook!' do
    let(:args) { ['foo', [1, 2, 3]] }

    def call
      integration.execute_web_hook!(*args)
    end

    it 'creates the webhook if necessary and executes it' do
      expect_next(ServiceHook).to receive(:execute).with(*args)
      expect { call }.to change(ServiceHook, :count).by(1)

      expect(integration.service_hook).to receive(:execute).with(*args)
      expect { call }.not_to change(ServiceHook, :count)
    end

    it 'raises an error if the service hook could not be saved' do
      expect_next(ServiceHook).to receive(:execute).with(*args)

      call
      integration.service_hook.integration = nil

      expect(integration.service_hook).not_to receive(:execute)
      expect { call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
