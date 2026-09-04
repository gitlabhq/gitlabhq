# frozen_string_literal: true

# Shared setup for feature specs asserting that a deep-link URL fragment (e.g. #L7) survives the
# multi-step sign-in and lands on the destination. Selenium's current_url fragment handling is
# unreliable, so the landing fragment is read with evaluate_script rather than matched against
# current_url.
RSpec.shared_context 'with a deep link that preserves the URL fragment' do
  let(:anchor) { 'L7' }
  let(:app_id) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }
  let(:namespace) { create(:namespace, owner: user) }
  let(:project) { create(:project, :private, namespace: namespace, organization: current_organization) }
  let(:deep_link) { project_path(project, anchor: anchor) }

  def expect_landed_on_deep_link
    expect(page).to have_current_path(project_path(project), ignore_query: true)
    expect(page.evaluate_script('window.location.hash')).to eq("##{anchor}")
  end
end
