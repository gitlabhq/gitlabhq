# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::Stores::LocalStore do
  describe '#enabled' do
    let(:local_store) { double(enabled: true) }

    subject(:local_store_enabled) { described_class.new(local_store).enabled }

    context 'when the pages_update_legacy_storage FF is disabled' do
      before do
        stub_feature_flags(pages_update_legacy_storage: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when the pages_update_legacy_storage FF is enabled' do
      it 'is equal to the original value' do
        expect(local_store_enabled).to eq(local_store.enabled)
      end
    end
  end
end
