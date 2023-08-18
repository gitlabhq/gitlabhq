# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pwa/manifest', feature_category: :navigation do
  describe 'view caching', :use_clean_rails_memory_store_fragment_caching do
    let(:appearance) { build_stubbed(:appearance, pwa_name: 'My GitLab') }

    context 'when appearance is unchanged' do
      it 'reuses the cached view' do
        allow(view).to receive(:current_appearance).and_return(appearance)
        allow(view).to receive(:appearance_pwa_name).and_call_original
        render
        render

        expect(view).to have_received(:appearance_pwa_name).once
      end
    end

    context 'when appearance has changed' do
      let(:changed_appearance) { build_stubbed(:appearance, pwa_name: 'My new GitLab') }

      it 'does not use the cached view' do
        allow(view).to receive(:current_appearance).and_return(appearance)
        allow(view).to receive(:appearance_pwa_name).and_call_original
        render

        allow(view).to receive(:current_appearance).and_return(changed_appearance)
        render

        expect(view).to have_received(:appearance_pwa_name).twice
        expect(rendered).to have_content 'My new GitLab'
      end
    end
  end
end
