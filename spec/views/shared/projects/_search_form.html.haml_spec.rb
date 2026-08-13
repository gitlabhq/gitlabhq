# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_search_form.html.haml', feature_category: :groups_and_projects do
  let(:language) { build(:programming_language, name: 'C++') }

  before do
    allow(view).to receive_messages(programming_languages: [language], search_language_placeholder: language.name)
    allow(view).to receive(:language_state_class).with(language).and_return('is-active')
    view.params.merge!(name: 'search term', language: '1', language_name: language.name)

    render 'shared/projects/search_form', topic_view: true
  end

  it 'submits and links with language names instead of legacy language IDs', :aggregate_failures do
    expect(rendered).to have_field('language_name', type: 'hidden', with: language.name)
    expect(rendered).to have_no_field('language', type: 'hidden')
    expect(rendered).to have_link(language.name, href: /\?language_name=C%2B%2B\z/)
    expect(rendered).to have_link(_('Any'), href: /\?\z/)
  end
end
