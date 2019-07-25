# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::Registry do
  let(:path) { nil }
  let(:registry) { described_class.new('http://example.com', path: path) }

  subject { registry }

  it { is_expected.to respond_to(:client) }
  it { is_expected.to respond_to(:uri) }
  it { is_expected.to respond_to(:path) }

  it { expect(subject).not_to be_nil }

  context '#path' do
    subject { registry.path }

    context 'path from URL' do
      it { is_expected.to eq('example.com') }
    end

    context 'custom path' do
      let(:path) { 'registry.example.com' }

      it { is_expected.to eq(path) }
    end
  end
end
