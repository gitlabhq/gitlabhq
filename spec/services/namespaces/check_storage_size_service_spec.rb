# frozen_string_literal: true

require 'spec_helper'

describe Namespaces::CheckStorageSizeService, '#execute' do
  let(:namespace) { build_stubbed(:namespace) }
  let(:user) { build(:user, namespace: namespace) }
  let(:service) { described_class.new(namespace, user) }
  let(:current_size) { 150.megabytes }
  let(:limit) { 100.megabytes }

  subject(:response) { service.execute }

  before do
    allow(namespace).to receive(:root_ancestor).and_return(namespace)

    root_storage_size = instance_double("RootStorageSize",
      current_size: current_size,
      limit: limit,
      usage_ratio: limit == 0 ? 0 : current_size.to_f / limit.to_f,
      above_size_limit?: current_size > limit
    )

    expect(Namespace::RootStorageSize).to receive(:new).and_return(root_storage_size)
  end

  context 'feature flag' do
    it 'is successful when disabled' do
      stub_feature_flags(namespace_storage_limit: false)

      expect(response).to be_success
    end

    it 'errors when enabled' do
      stub_feature_flags(namespace_storage_limit: true)

      expect(response).to be_error
    end

    it 'is successful when feature flag is activated for another namespace' do
      stub_feature_flags(namespace_storage_limit: build(:namespace))

      expect(response).to be_success
    end

    it 'errors when feature flag is activated for the current namespace' do
      stub_feature_flags(namespace_storage_limit: namespace)

      expect(response).to be_error
      expect(response.message).to be_present
    end
  end

  context 'when limit is set to 0' do
    let(:limit) { 0 }

    it 'is successful and has no payload' do
      expect(response).to be_success
      expect(response.payload).to be_empty
    end
  end

  context 'when current size is below threshold' do
    let(:current_size) { 10.megabytes }

    it 'is successful and has no payload' do
      expect(response).to be_success
      expect(response.payload).to be_empty
    end
  end

  context 'when not admin of the namespace' do
    let(:other_namespace) { build_stubbed(:namespace) }

    subject(:response) { described_class.new(other_namespace, user).execute }

    before do
      allow(other_namespace).to receive(:root_ancestor).and_return(other_namespace)
    end

    it 'errors and has no payload' do
      expect(response).to be_error
      expect(response.payload).to be_empty
    end
  end

  context 'when providing the child namespace' do
    let(:namespace) { build_stubbed(:group) }
    let(:child_namespace) { build_stubbed(:group, parent: namespace) }

    subject(:response) { described_class.new(child_namespace, user).execute }

    before do
      allow(child_namespace).to receive(:root_ancestor).and_return(namespace)
      namespace.add_owner(user)
    end

    it 'uses the root namespace' do
      expect(response).to be_error
    end
  end

  describe 'payload alert_level' do
    subject { service.execute.payload[:alert_level] }

    context 'when above info threshold' do
      let(:current_size) { 50.megabytes }

      it { is_expected.to eq(:info) }
    end

    context 'when above warning threshold' do
      let(:current_size) { 75.megabytes }

      it { is_expected.to eq(:warning) }
    end

    context 'when above alert threshold' do
      let(:current_size) { 95.megabytes }

      it { is_expected.to eq(:alert) }
    end

    context 'when above error threshold' do
      let(:current_size) { 100.megabytes }

      it { is_expected.to eq(:error) }
    end
  end

  describe 'payload explanation_message' do
    subject(:response) { service.execute.payload[:explanation_message] }

    context 'when above limit' do
      let(:current_size) { 110.megabytes }

      it 'returns message with read-only warning' do
        expect(response).to include("#{namespace.name} is now read-only")
      end
    end

    context 'when below limit' do
      let(:current_size) { 60.megabytes }

      it { is_expected.to include('If you reach 100% storage capacity') }
    end
  end

  describe 'payload usage_message' do
    let(:current_size) { 60.megabytes }

    subject(:response) { service.execute.payload[:usage_message] }

    it 'returns current usage information' do
      expect(response).to include("60 MB of 100 MB")
      expect(response).to include("60%")
    end
  end

  describe 'payload root_namespace' do
    subject(:response) { service.execute.payload[:root_namespace] }

    it { is_expected.to eq(namespace) }
  end
end
