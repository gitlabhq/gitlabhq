# frozen_string_literal: true

RSpec.shared_context 'with GLFM example snapshot fixtures' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'glfm_group', owners: user) }

  let_it_be(:project) do
    # NOTE: We hardcode the IDs on all fixtures to prevent variability in the
    #       rendered HTML/Prosemirror JSON, and to minimize the need for normalization:
    #       https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#normalization
    create(:project, :repository, creator: user, group: group, path: 'glfm_project', id: 77777)
  end

  let_it_be(:project_snippet) { create(:project_snippet, title: 'glfm_project_snippet', id: 88888, project: project) }
  let_it_be(:personal_snippet) { create(:snippet, id: 99999) }

  before do
    # Set 'GITLAB_TEST_FOOTNOTE_ID' in order to override random number generation in
    # Banzai::Filter::FootnoteFilter#random_number, and thus avoid the need to
    # perform normalization on the value. See:
    # https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#normalization
    stub_env('GITLAB_TEST_FOOTNOTE_ID', 42)

    stub_licensed_features(group_wikis: true)
    sign_in(user)
  end
end
