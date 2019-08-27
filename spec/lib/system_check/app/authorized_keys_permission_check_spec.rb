# frozen_string_literal: true

require 'spec_helper'

describe SystemCheck::App::AuthorizedKeysPermissionCheck do
  subject { described_class.new }

  describe '#skip?' do
    context 'authorized keys enabled' do
      it 'returns false' do
        expect(subject.skip?).to eq(false)
      end
    end

    context 'authorized keys not enabled' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'returns true' do
        expect(subject.skip?).to eq(true)
      end
    end
  end

  describe '#check?' do
    let(:authorized_keys) { double }

    before do
      allow(Gitlab::AuthorizedKeys).to receive(:new).and_return(authorized_keys)
      allow(authorized_keys).to receive(:accessible?).and_return(accessible?)
    end

    context 'authorized keys is accessible' do
      let(:accessible?) { true }

      it 'returns true' do
        expect(subject.check?).to eq(true)
      end
    end

    context 'authorized keys is not accessible' do
      let(:accessible?) { false }

      it 'returns false' do
        expect(subject.check?).to eq(false)
      end
    end
  end
end
