# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::StorageSettings do
  describe "#initialize" do
    context 'when the storage contains no path' do
      it 'raises an error' do
        expect do
          described_class.new("foo" => {})
        end.to raise_error(described_class::InvalidConfigurationError)
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
          described_class.new("path" => Rails.root)
        end.not_to raise_error
      end
    end
  end

  describe '.gitaly_address' do
    context 'when the storage settings have no gitaly address but one is requested' do
      it 'raises an error' do
        expect do
          described_class.new("path" => Rails.root).gitaly_address
        end.to raise_error("key not found: \"gitaly_address\"")
      end
    end

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
    context 'when Rugged is enabled', :enable_rugged do
      it 'returns false' do
        expect(described_class.disk_access_denied?).to be_falsey
      end
    end

    context 'when Rugged is disabled' do
      it 'returns true' do
        expect(described_class.disk_access_denied?).to be_truthy
      end
    end
  end
end
