# frozen_string_literal: true

RSpec.shared_examples 'rejecting project protection rules request when not enough permissions' do
  using RSpec::Parameterized::TableSyntax

  where(:user_role, :status) do
    :reporter  | :forbidden
    :developer | :forbidden
    :guest     | :forbidden
    nil        | :not_found
  end

  with_them do
    before do
      project.send(:"add_#{user_role}", api_user) if user_role
    end

    it_behaves_like 'returning response status', params[:status]
  end
end

RSpec.shared_examples 'rejecting protection rules request when handling rule ids' do
  using RSpec::Parameterized::TableSyntax

  let(:valid_project_id) { project.id }
  let(:valid_protection_rule_id) { protection_rule.id }
  let(:other_project_id) { other_project.id }
  let(:url) { "/projects/#{project_id}/#{path}" }

  where(:project_id, :protection_rule_id, :status) do
    ref(:valid_project_id) | 'invalid'                | :bad_request
    ref(:valid_project_id) | non_existing_record_id   | :not_found
    ref(:other_project_id) | ref(:valid_protection_rule_id) | :not_found
  end

  with_them do
    it_behaves_like 'returning response status', params[:status]
  end
end

RSpec.shared_examples 'rejecting protection rules request when invalid project' do
  using RSpec::Parameterized::TableSyntax

  let(:url) { "/projects/#{project_id}/#{path}" }

  where(:project_id, :status) do
    'invalid'               | :not_found
    non_existing_record_id  | :not_found
  end

  with_them do
    it_behaves_like 'returning response status', params[:status]
  end
end
