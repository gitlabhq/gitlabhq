# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSetting::TermPolicy do
  include TermsHelper

  let_it_be(:term) { create(:term) }

  let(:user) { create(:user) }

  subject(:policy) { described_class.new(user, term) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  it 'has the correct permissions', :aggregate_failures do
    is_expected.to be_allowed(:accept_terms)
    is_expected.to be_allowed(:decline_terms)
  end

  context 'for anonymous users' do
    let(:user) { nil }

    it 'has the correct permissions', :aggregate_failures do
      is_expected.to be_disallowed(:accept_terms)
      is_expected.to be_disallowed(:decline_terms)
    end
  end

  context 'when the terms are not current' do
    before do
      create(:term)
    end

    it 'has the correct permissions', :aggregate_failures do
      is_expected.to be_disallowed(:accept_terms)
      is_expected.to be_disallowed(:decline_terms)
    end
  end

  context 'when the user already accepted the terms' do
    before do
      accept_terms(user)
    end

    it 'has the correct permissions', :aggregate_failures do
      is_expected.to be_disallowed(:accept_terms)
      is_expected.to be_allowed(:decline_terms)
    end
  end
end
