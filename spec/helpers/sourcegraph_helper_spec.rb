# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SourcegraphHelper do
  describe '#sourcegraph_url_message' do
    let(:sourcegraph_url) { 'http://sourcegraph.example.com' }
    let(:public_only) { false }
    let(:is_com) { true }

    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url).and_return(sourcegraph_url)
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url_is_com?).and_return(is_com)
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_public_only).and_return(public_only)
    end

    subject { helper.sourcegraph_url_message }

    context 'with .com sourcegraph url' do
      it { is_expected.to have_text('Uses %{linkStart}Sourcegraph.com%{linkEnd}. This feature is experimental.') }
    end

    context 'with custom sourcegraph url' do
      let(:is_com) { false }

      it { is_expected.to have_text('Uses a custom %{linkStart}Sourcegraph instance%{linkEnd}. This feature is experimental.') }
    end

    context 'when not limited by feature or public only' do
      it { is_expected.to eq 'Uses %{linkStart}Sourcegraph.com%{linkEnd}. This feature is experimental.' }
    end

    context 'when limited by public only' do
      let(:public_only) { true }

      it { is_expected.to eq 'Uses %{linkStart}Sourcegraph.com%{linkEnd}. This feature is experimental and limited to public projects.' }
    end
  end
end
