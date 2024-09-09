# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_terms_of_service_notice', feature_category: :system_access do
  let(:enforce_terms) { false }

  before do
    stub_application_setting(enforce_terms: enforce_terms)
  end

  context 'when terms are not enabled' do
    it 'does not render anything' do
      expect { render_terms }.to raise_error(TypeError)
    end
  end

  context 'when terms are enabled' do
    let(:enforce_terms) { true }

    before do
      render_terms
    end

    subject { rendered }

    it { is_expected.to have_content(_('By clicking')) }
  end

  def render_terms
    render 'devise/shared/terms_of_service_notice', button_text: '_button_text_'
  end
end
