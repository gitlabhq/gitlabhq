require 'rails_helper'

describe 'admin/users/index' do
  it 'includes "Send email to users" link' do
    assign(:users, User.all.page(1))

    render

    expect(rendered).to have_link 'Send email to users', href: admin_email_path
  end
end
