# frozen_string_literal: true

# Builds a project where a branch and a tag share a name (or embed one another's
# ref namespace prefix) while pointing at divergent content. Used to exercise
# tag/branch ambiguity in views that render archive download links
# (https://gitlab.com/gitlab-org/gitlab/-/issues/578988).
#
# Parameters (passed via `include_context`):
#   - branch_name: the short branch name to create (e.g. 'release' or 'refs/tags/release')
#   - tag_name:    the short tag name to create (e.g. 'refs/heads/release' or 'release')
#
# The refs are written directly (rather than via commit_files) because Git rejects
# creating a branch/tag whose name embeds another ref namespace (e.g. a branch
# named "refs/tags/release") through the normal commit path.
#
# Provides:
#   - ambiguous_project: the project with the fixture
#   - file_path:         the path present on both refs with divergent content
#   - branch_sha / tag_sha: the resolved commit SHAs (guaranteed to differ)
RSpec.shared_context 'with an ambiguous branch and tag fixture' do |branch_name:, tag_name:|
  let_it_be(:file_path) { 'file.txt' }
  let_it_be(:ambiguous_project) { create(:project, :public, :repository) }

  let_it_be(:fixture_shas) do
    creator = ambiguous_project.creator
    repo = ambiguous_project.repository

    repo.create_file(creator, file_path, 'branch content', message: 'branch content', branch_name: 'branch-scratch')
    repo.raw_repository.write_ref("refs/heads/#{branch_name}", repo.commit('branch-scratch').id)

    repo.create_file(creator, file_path, 'tag content', message: 'tag content', branch_name: 'tag-scratch')
    repo.raw_repository.write_ref("refs/tags/#{tag_name}", repo.commit('tag-scratch').id)

    repo.expire_all_method_caches

    { branch: repo.commit("refs/heads/#{branch_name}").id, tag: repo.commit("refs/tags/#{tag_name}").id }
  end

  let_it_be(:branch_sha) { fixture_shas[:branch] }
  let_it_be(:tag_sha) { fixture_shas[:tag] }

  before do
    raise "fixture changed: #{branch_name} must exist as a branch" unless
      ambiguous_project.repository.branch_names.include?(branch_name)

    raise "fixture changed: #{tag_name} must exist as a tag" unless
      ambiguous_project.repository.tag_names.include?(tag_name)
  end
end
