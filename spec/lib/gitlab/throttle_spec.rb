# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Throttle do
  describe '.protected_paths_enabled?' do
    subject { described_class.protected_paths_enabled? }

    it 'returns Application Settings throttle_protected_paths_enabled?' do
      expect(Gitlab::CurrentSettings.current_application_settings).to receive(:throttle_protected_paths_enabled?)

      subject
    end
  end

  describe '.bypass_header' do
    subject { described_class.bypass_header }

    it 'is nil' do
      expect(subject).to be_nil
    end

    context 'when a header is configured' do
      before do
        stub_env('GITLAB_THROTTLE_BYPASS_HEADER', 'My-Custom-Header')
      end

      it 'is a funny upper case rack key' do
        expect(subject).to eq('HTTP_MY_CUSTOM_HEADER')
      end
    end
  end
end
