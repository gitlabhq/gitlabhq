# frozen_string_literal: true

RSpec.shared_examples 'shared super sidebar context' do
  it 'returns sidebar values for logged-in users and logged-out users', :use_clean_rails_memory_store_caching do
    expect(subject).to include({
      current_menu_items: nil,
      current_context_header: nil,
      support_path: helper.support_url,
      display_whats_new: helper.display_whats_new?,
      whats_new_most_recent_release_items_count: helper.whats_new_most_recent_release_items_count,
      whats_new_version_digest: helper.whats_new_version_digest,
      show_version_check: helper.show_version_check?,
      gitlab_version: Gitlab.version_info,
      gitlab_version_check: helper.gitlab_version_check,
      search: {
        search_path: search_path,
        issues_path: issues_dashboard_path,
        mr_path: merge_requests_dashboard_path,
        autocomplete_path: search_autocomplete_path,
        search_context: helper.header_search_context
      },
      panel_type: panel_type
    })
  end
end

RSpec.shared_examples 'logged-out super-sidebar context' do
  subject do
    helper.super_sidebar_context(nil, group: nil, project: nil, panel: panel, panel_type: panel_type)
  end

  it_behaves_like 'shared super sidebar context'

  it { is_expected.to include({ is_logged_in: false }) }

  it { expect(subject[:context_switcher_links]).to be_an(Array) }
end
