# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'errors/omniauth_error' do
  let(:provider) { FFaker::Product.brand }
  let(:error) { FFaker::Lorem.sentence }

  before do
    assign(:provider, provider)
    assign(:error, error)
  end

  it 'renders template' do
    render

    expect(rendered).to have_content(provider)
    expect(rendered).to have_content(_('Sign-in failed because %{error}.') % { error: error })
    expect(rendered).to have_link('Sign in')
    expect(rendered).to have_content(_('If none of the options work, try contacting a GitLab administrator.'))
  end
end
