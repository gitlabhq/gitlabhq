# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::TransferLogging, feature_category: :groups_and_projects do
  let(:host_class) do
    Class.new do
      include Namespaces::TransferLogging

      public :build_transfer_log_payload
      public :transfer_namespace_type
      public :elapsed_seconds
    end
  end

  let(:instance) { host_class.new }

  describe '#build_transfer_log_payload' do
    subject(:payload) { instance.build_transfer_log_payload(message: 'Test message') }

    it 'returns a stringified hash' do
      expect(payload).to be_a(Hash)
      expect(payload.keys).to all(be_a(String))
    end

    it 'includes the message' do
      expect(payload['message']).to eq('Test message')
    end

    it 'includes a correlation_id' do
      expect(payload['correlation_id']).to be_a(String).and be_present
    end

    it 'includes a class key from Gitlab::Loggable' do
      expect(payload['class_name']).to be_a(String)
    end

    context 'when namespace is a Group' do
      let_it_be(:group) { create(:group) }

      subject(:payload) { instance.build_transfer_log_payload(message: 'Test', namespace: group) }

      it 'sets gl_namespace_id to the group id' do
        expect(payload['gl_namespace_id']).to eq(group.id)
      end

      it 'sets namespace_type to "group"' do
        expect(payload['namespace_type']).to eq('group')
      end

      it 'sets transfer_state from the namespace state' do
        expect(payload['transfer_state']).to eq(group.state)
      end
    end

    context 'when namespace is a Namespaces::ProjectNamespace' do
      let_it_be(:project) { create(:project) }

      subject(:payload) do
        instance.build_transfer_log_payload(message: 'Test', namespace: project.project_namespace)
      end

      it 'sets gl_namespace_id to the project namespace id' do
        expect(payload['gl_namespace_id']).to eq(project.project_namespace.id)
      end

      it 'sets namespace_type to "project"' do
        expect(payload['namespace_type']).to eq('project')
      end
    end

    context 'when namespace is nil' do
      subject(:payload) { instance.build_transfer_log_payload(message: 'Test', namespace: nil) }

      it 'sets gl_namespace_id to nil' do
        expect(payload['gl_namespace_id']).to be_nil
      end

      it 'sets namespace_type to nil' do
        expect(payload['namespace_type']).to be_nil
      end
    end

    context 'when an error is provided' do
      let(:error) { StandardError.new('something went wrong') }

      subject(:payload) { instance.build_transfer_log_payload(message: 'Test', error: error) }

      it 'sets error_type to the exception class name' do
        expect(payload['error_type']).to eq('StandardError')
      end

      it 'sets error_message to the exception message' do
        expect(payload['error_message']).to eq('something went wrong')
      end
    end

    context 'when no error is provided' do
      it 'sets error_type to nil' do
        expect(payload['error_type']).to be_nil
      end

      it 'sets error_message to nil' do
        expect(payload['error_message']).to be_nil
      end
    end

    context 'with optional timing fields' do
      subject(:payload) do
        instance.build_transfer_log_payload(
          message: 'Test',
          duration_s: 1.5,
          queue_wait_s: 0.3,
          retry_count: 2
        )
      end

      it 'includes duration_s' do
        expect(payload['duration_s']).to eq(1.5)
      end

      it 'includes queue_wait_s' do
        expect(payload['queue_wait_s']).to eq(0.3)
      end

      it 'includes retry_count' do
        expect(payload['retry_count']).to eq(2)
      end
    end

    context 'with extra caller-specific fields' do
      subject(:payload) do
        instance.build_transfer_log_payload(message: 'Test', group_id: 42, new_parent_group_id: 99)
      end

      it 'merges extra fields into the payload' do
        expect(payload['group_id']).to eq(42)
        expect(payload['new_parent_group_id']).to eq(99)
      end
    end

    context 'when caller overrides a standardised field' do
      subject(:payload) do
        instance.build_transfer_log_payload(message: 'Test', error_message: 'custom override')
      end

      it 'uses the caller-provided value' do
        expect(payload['error_message']).to eq('custom override')
      end
    end
  end

  describe '#transfer_namespace_type' do
    context 'when namespace is a Group' do
      let_it_be(:group) { create(:group) }

      it 'returns "group"' do
        expect(instance.transfer_namespace_type(group)).to eq('group')
      end
    end

    context 'when namespace is a Namespaces::ProjectNamespace' do
      let_it_be(:project) { create(:project) }

      it 'returns "project"' do
        expect(instance.transfer_namespace_type(project.project_namespace)).to eq('project')
      end
    end

    context 'when namespace is nil' do
      it 'returns nil' do
        expect(instance.transfer_namespace_type(nil)).to be_nil
      end
    end

    context 'when namespace is an unknown type' do
      let(:unknown_namespace) { build_stubbed(:user_namespace) }

      it 'returns the class name' do
        expect(instance.transfer_namespace_type(unknown_namespace)).to eq(unknown_namespace.class.name)
      end
    end
  end

  describe '#elapsed_seconds' do
    it 'returns a float representing elapsed time' do
      start = Gitlab::Metrics::System.monotonic_time

      result = instance.elapsed_seconds(start)

      expect(result).to be_a(Float)
      expect(result).to be >= 0
    end

    it 'rounds to 6 decimal places' do
      start = Gitlab::Metrics::System.monotonic_time

      result = instance.elapsed_seconds(start)

      expect(result.to_s.split('.').last.length).to be <= 6
    end
  end
end
