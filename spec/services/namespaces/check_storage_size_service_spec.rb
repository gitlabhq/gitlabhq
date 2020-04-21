# frozen_string_literal: true

require 'spec_helper'

describe Namespaces::CheckStorageSizeService, '#execute' do
  let_it_be(:root_group) { create(:group) }
  let(:nested_group) { create(:group, parent: root_group) }
  let(:service) { described_class.new(nested_group) }
  let(:current_size) { 150.megabytes }
  let(:limit) { 100 }

  subject { service.execute }

  before do
    stub_application_setting(namespace_storage_size_limit: limit)

    create(:namespace_root_storage_statistics, namespace: root_group, storage_size: current_size)
  end

  context 'feature flag' do
    it 'is successful when disabled' do
      stub_feature_flags(namespace_storage_limit: false)

      expect(subject).to be_success
    end

    it 'errors when enabled' do
      stub_feature_flags(namespace_storage_limit: true)

      expect(subject).to be_error
    end

    it 'is successful when disabled for the current group' do
      stub_feature_flags(namespace_storage_limit: { enabled: false, thing: root_group })

      expect(subject).to be_success
    end

    it 'is successful when feature flag is activated for another group' do
      stub_feature_flags(namespace_storage_limit: false)
      stub_feature_flags(namespace_storage_limit: { enabled: true, thing: create(:group) })

      expect(subject).to be_success
    end

    it 'errors when feature flag is activated for the current group' do
      stub_feature_flags(namespace_storage_limit: { enabled: true, thing: root_group })

      expect(subject).to be_error
    end
  end

  context 'when limit is set to 0' do
    let(:limit) { 0 }

    it { is_expected.to be_success }

    it 'does not respond with a payload' do
      result = subject

      expect(result.message).to be_nil
      expect(result.payload).to be_empty
    end
  end

  context 'when current size is below threshold to show an alert' do
    let(:current_size) { 10.megabytes }

    it { is_expected.to be_success }
  end

  context 'when current size exceeds limit' do
    it 'returns an error with a payload' do
      result = subject
      current_usage_message = result.payload[:current_usage_message]

      expect(result).to be_error
      expect(result.message).to include("#{root_group.name} is now read-only.")
      expect(current_usage_message).to include("150%")
      expect(current_usage_message).to include(root_group.name)
      expect(current_usage_message).to include("150 MB of 100 MB")
      expect(result.payload[:usage_ratio]).to eq(1.5)
    end
  end

  context 'when current size is below limit but should show an alert' do
    let(:current_size) { 50.megabytes }

    it 'returns success with a payload' do
      result = subject
      current_usage_message = result.payload[:current_usage_message]

      expect(result).to be_success
      expect(result.message).to be_present
      expect(current_usage_message).to include("50%")
      expect(current_usage_message).to include(root_group.name)
      expect(current_usage_message).to include("50 MB of 100 MB")
      expect(result.payload[:usage_ratio]).to eq(0.5)
    end
  end
end
