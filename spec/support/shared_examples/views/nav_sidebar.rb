# frozen_string_literal: true

shared_examples 'has nav sidebar' do
  it 'has collapsed nav sidebar on mobile' do
    render

    expect(rendered).to have_selector('.nav-sidebar.sidebar-collapsed-mobile')
  end
end
