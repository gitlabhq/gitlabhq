# frozen_string_literal: true

RSpec.shared_context 'with ambiguous refs for controllers' do
  before do
    expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original # rubocop:disable RSpec/ExpectInHook
    project.repository.add_tag(project.creator, 'ambiguous_ref', RepoHelpers.sample_commit.id)
    project.repository.add_branch(project.creator, 'ambiguous_ref', RepoHelpers.another_sample_commit.id)
  end

  after do
    project.repository.rm_tag(project.creator, 'ambiguous_ref')
    project.repository.rm_branch(project.creator, 'ambiguous_ref')
  end
end
