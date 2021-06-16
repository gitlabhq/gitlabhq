# frozen_string_literal: true

RSpec.shared_context 'read ci configuration for sast enabled project' do
  let_it_be(:gitlab_ci_yml_content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_for_sast.yml'))
  end

  let_it_be(:gitlab_ci_yml_excluded_analyzers_content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_for_sast_excluded_analyzers.yml'))
  end

  let_it_be(:project) { create(:project, :repository) }
end
