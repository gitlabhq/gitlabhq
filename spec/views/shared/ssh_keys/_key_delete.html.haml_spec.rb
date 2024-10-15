# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/ssh_keys/_key_delete.html.haml' do
  it 'has text', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498014' do
    render partial: 'shared/ssh_keys/key_delete', formats: :html, locals: { button_data: '' }

    expect(rendered).to have_button('Delete')
  end
end
