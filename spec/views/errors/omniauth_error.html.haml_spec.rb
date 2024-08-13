# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'errors/omniauth_error' do
  let(:provider) { FFaker::Product.brand }
  let(:error) { FFaker::Lorem.sentence }

  before do
    assign(:provider, provider)
  end

  it 'renders template' do
    render

    expect(rendered).to have_content(provider)
    expect(rendered).to have_link('Sign in')
    expect(rendered).to have_content(
      _('If you are unable to sign in or recover your password, contact a GitLab administrator.')
    )
  end
end
