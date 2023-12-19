# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::StorageSettings, feature_category: :gitaly do
  describe "#initialize" do
    context 'when the storage contains no gitaly_address' do
      it 'raises an error' do
        expect do
          described_class.new("foo" => {})
        end.to raise_error(described_class::InvalidConfigurationError, described_class::INVALID_STORAGE_MESSAGE)
      end
    end

    context "when the argument isn't a hash" do
      it 'raises an error' do
        expect do
          described_class.new("test")
        end.to raise_error("expected a Hash, got a String")
      end
    end

    context 'when the storage is valid' do
      it 'raises no error' do
        expect do
          described_class.new("gitaly_address" => "unix:tmp/tests/gitaly/gitaly.socket")
        end.not_to raise_error
      end
    end
  end

  describe '.gitaly_address' do
    context 'when the storage settings have a gitaly address and one is requested' do
      it 'returns the setting value' do
        expect(described_class.new("path" => Rails.root, "gitaly_address" => "test").gitaly_address).to eq("test")
      end
    end

    context 'when the storage settings have a gitaly address keyed symbolically' do
      it 'raises no error' do
        expect do
          described_class.new("path" => Rails.root, :gitaly_address => "test").gitaly_address
        end.not_to raise_error
      end
    end

    context 'when the storage settings have a gitaly address keyed with a string' do
      it 'raises no error' do
        expect do
          described_class.new("path" => Rails.root, "gitaly_address" => "test").gitaly_address
        end.not_to raise_error
      end
    end
  end

  describe '.disk_access_denied?' do
    subject { described_class.disk_access_denied? }

    it { is_expected.to be_truthy }

    context 'in case of an exception' do
      before do
        allow(described_class).to receive(:temporarily_allowed?).and_raise('boom')
      end

      it { is_expected.to be_falsey }
    end
  end
end
