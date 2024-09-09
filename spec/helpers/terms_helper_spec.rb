# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TermsHelper, feature_category: :system_access do
  let_it_be(:current_user) { build(:user) }
  let_it_be(:terms) { build(:term) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe '#terms_data' do
    let_it_be(:redirect) { '%2F' }
    let_it_be(:terms_markdown) { 'Lorem ipsum dolor sit amet' }
    let_it_be(:accept_path) { '/-/users/terms/14/accept?redirect=%2F' }
    let_it_be(:decline_path) { '/-/users/terms/14/decline?redirect=%2F' }

    subject(:result) { Gitlab::Json.parse(helper.terms_data(terms, redirect)) }

    it 'returns correct json' do
      expect(helper).to receive(:markdown_field).with(terms, :terms).and_return(terms_markdown)
      expect(helper).to receive(:can?).with(current_user, :accept_terms, terms).and_return(true)
      expect(helper).to receive(:can?).with(current_user, :decline_terms, terms).and_return(true)
      expect(helper).to receive(:accept_term_path).with(terms, { redirect: redirect }).and_return(accept_path)
      expect(helper).to receive(:decline_term_path).with(terms, { redirect: redirect }).and_return(decline_path)

      expected = {
        terms: terms_markdown,
        permissions: {
          can_accept: true,
          can_decline: true
        },
        paths: {
          accept: accept_path,
          decline: decline_path,
          root: root_path
        }
      }.as_json

      expect(result).to eq(expected)
    end
  end

  describe '#terms_service_notice_link', :aggregate_failures do
    let(:button_text) { 'terms-text' }

    subject(:result) { helper.terms_service_notice_link(button_text) }

    it 'returns correct html' do
      expect(result).to have_link('', href: terms_path)
      expect(result).to have_content(_('By clicking'))
      expect(result).to have_content(button_text)
      expect(result).to have_content(_('or registering through a third party you accept the'))
    end
  end
end
