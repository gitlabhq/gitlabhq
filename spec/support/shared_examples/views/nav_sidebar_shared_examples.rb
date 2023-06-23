# frozen_string_literal: true

RSpec.shared_examples 'has nav sidebar' do
  it 'has collapsed nav sidebar on mobile' do
    render

    expect(rendered).to have_selector('.nav-sidebar')
    expect(rendered).not_to have_selector('.sidebar-collapsed-desktop')
    expect(rendered).not_to have_selector('.sidebar-expanded-mobile')
  end
end

RSpec.shared_examples 'sidebar includes snowplow attributes' do |track_action, track_label, track_property|
  specify do
    stub_application_setting(snowplow_enabled: true)

    render

    expect(rendered)
      .to have_css(
        ".nav-sidebar[data-track-action=\"#{track_action}\"]" \
        "[data-track-label=\"#{track_label}\"][data-track-property=\"#{track_property}\"]"
      )
  end
end
