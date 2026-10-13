# frozen_string_literal: true

# Wraps the generic 'enforcing job token policies' example with the setup common to every work item
# REST endpoint, so each endpoint only has to say what its path looks like.
#
# The including context must define:
#   - `job_token_path`  a lambda taking the project and returning the endpoint path, for example
#                       `->(project) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/notes" }`
#
# Only the project-scoped routes are covered: they resolve through `find_project!`, which is what
# actually calls `authorize_job_token_policies!`.
RSpec.shared_examples 'a work item endpoint enforcing job token policies' do
  it_behaves_like 'enforcing job token policies', :read_work_items,
    allow_public_access_for_enabled_project_features: :issues do
    let(:request) do
      get api(job_token_path.call(source_project)), params: { job_token: target_job.token }
    end
  end
end
