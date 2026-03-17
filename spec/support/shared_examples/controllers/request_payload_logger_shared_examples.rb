# frozen_string_literal: true

RSpec.shared_examples 'RequestPayloadLogger information appended' do
  it 'logs custom information in the payload' do
    expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
      method.call(payload)

      expect(payload[:remote_ip]).to be_present
      expect(payload[:username]).to eq(user.username)
      expect(payload[:user_id]).to be_present
      expect(payload[:ua]).to be_present
    end

    subject
  end
end
