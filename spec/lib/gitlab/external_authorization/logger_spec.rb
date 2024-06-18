# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExternalAuthorization::Logger do
  let(:request_time) { Time.parse('2018-03-26 20:22:15') }

  def fake_access(has_access, user, load_type = :request)
    access = double('access')
    allow(access).to receive_messages(user: user,
      has_access?: has_access,
      loaded_at: request_time,
      label: 'dummy_label',
      load_type: load_type)

    access
  end

  describe '.log_access' do
    it 'logs a nice message for an access request' do
      expected_message = "GRANTED admin@example.com access to 'dummy_label' (the/project/path)"
      fake_access = fake_access(true, build(:user, email: 'admin@example.com'))

      expect(described_class).to receive(:info).with(expected_message)

      described_class.log_access(fake_access, 'the/project/path')
    end

    it 'does not trip without a project path' do
      expected_message = "DENIED admin@example.com access to 'dummy_label'"
      fake_access = fake_access(false, build(:user, email: 'admin@example.com'))

      expect(described_class).to receive(:info).with(expected_message)

      described_class.log_access(fake_access, nil)
    end

    it 'adds the load time for cached accesses' do
      expected_message = "DENIED admin@example.com access to 'dummy_label' - cache #{request_time}"
      fake_access = fake_access(false, build(:user, email: 'admin@example.com'), :cache)

      expect(described_class).to receive(:info).with(expected_message)

      described_class.log_access(fake_access, nil)
    end
  end
end
