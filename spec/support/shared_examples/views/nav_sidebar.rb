# frozen_string_literal: true

shared_examples 'has nav sidebar' do
  it 'has collapsed nav sidebar on mobile' do
    render

    expect(rendered).to have_selector('.nav-sidebar')
    expect(rendered).not_to have_selector('.sidebar-collapsed-desktop')
    expect(rendered).not_to have_selector('.sidebar-expanded-mobile')
  end
end
