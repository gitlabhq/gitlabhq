shared_examples 'issue sidebar stays collapsed on mobile' do
  before do
    resize_screen_xs
  end

  it 'keeps the sidebar collapsed' do
    expect(page).not_to have_css('.right-sidebar.right-sidebar-collapsed')
  end
end
