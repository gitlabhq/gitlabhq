# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::RequestChannel, feature_category: :importers do
  describe '.detect' do
    let(:request) { instance_double(ActionDispatch::Request, user_agent: user_agent) }

    context 'when the user agent identifies Congregate' do
      let(:user_agent) { 'GitLabApiClient' }

      it { expect(described_class.detect(request)).to eq(:congregate) }

      context 'with a version suffix' do
        let(:user_agent) { 'GitLabApiClient/2.0 python-requests/2.31.0' }

        it { expect(described_class.detect(request)).to eq(:congregate) }
      end
    end

    context 'when the user agent is any other API client' do
      let(:user_agent) { 'python-requests/2.31.0' }

      it { expect(described_class.detect(request)).to eq(:api) }
    end

    context 'when the user agent is blank' do
      let(:user_agent) { nil }

      it { expect(described_class.detect(request)).to eq(:api) }
    end

    context 'when the request is nil' do
      it { expect(described_class.detect(nil)).to eq(:api) }
    end
  end

  describe '.stash and .stashed', :request_store do
    it 'returns the stashed value' do
      described_class.stash(:ui)

      expect(described_class.stashed).to eq(:ui)
    end

    it 'returns nil when nothing was stashed' do
      expect(described_class.stashed).to be_nil
    end

    it 'does not use the generic :request_channel request store key' do
      described_class.stash(:ui)

      expect(Gitlab::SafeRequestStore[:request_channel]).to be_nil
    end
  end
end
