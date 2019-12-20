# frozen_string_literal: true

# This pending test can be removed when `single_mr_diff_view` is enabled by default
# disabling the feature flag above is then not needed anymore.
RSpec.shared_examples 'rendering a single diff version' do |attribute|
  before do
    stub_feature_flags(diffs_batch_load: false)
  end

  pending 'allows editing diff settings single_mr_diff_view is enabled' do
    project = create(:project, :repository)
    user = project.creator
    merge_request = create(:merge_request, source_project: project)
    stub_feature_flags(single_mr_diff_view: true)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))

    expect(page).to have_selector('.js-show-diff-settings')
  end
end
