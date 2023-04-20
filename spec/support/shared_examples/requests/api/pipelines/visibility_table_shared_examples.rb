# frozen_string_literal: true

RSpec.shared_examples 'pipelines visibility table' do
  using RSpec::Parameterized::TableSyntax

  let(:ci_user) { create(:user) }
  let(:api_user) { user_role && ci_user }

  let(:pipelines_api_path) do
    "/projects/#{project.id}/pipelines"
  end

  let(:response_200) do
    a_collection_containing_exactly(
      a_hash_including('sha', 'ref', 'status', 'web_url', 'id' => pipeline.id)
    )
  end

  let(:response_40x) do
    a_hash_including('message')
  end

  let(:expected_response) do
    if response_status == 200
      response_200
    else
      response_40x
    end
  end

  let(:api_response) { json_response }

  let(:visibility_levels) do
    {
      private: Gitlab::VisibilityLevel::PRIVATE,
      internal: Gitlab::VisibilityLevel::INTERNAL,
      public: Gitlab::VisibilityLevel::PUBLIC
    }
  end

  let(:builds_access_levels) do
    {
      enabled: ProjectFeature::ENABLED,
      private: ProjectFeature::PRIVATE
    }
  end

  let(:project_attributes) do
    {
      visibility_level: visibility_levels[visibility_level],
      public_builds: public_builds
    }
  end

  let(:project_feature_attributes) do
    {
      builds_access_level: builds_access_levels[builds_access_level]
    }
  end

  where(:visibility_level, :builds_access_level, :public_builds, :is_admin, :user_role, :response_status) do
    :private  | :enabled | true  | true  | :non_member | 200
    :private  | :enabled | true  | true  | :guest      | 200
    :private  | :enabled | true  | true  | :reporter   | 200
    :private  | :enabled | true  | true  | :developer  | 200
    :private  | :enabled | true  | true  | :maintainer | 200

    :private  | :enabled | true  | false | nil         | 404
    :private  | :enabled | true  | false | :non_member | 404
    :private  | :enabled | true  | false | :guest      | 200
    :private  | :enabled | true  | false | :reporter   | 200
    :private  | :enabled | true  | false | :developer  | 200
    :private  | :enabled | true  | false | :maintainer | 200

    :private  | :enabled | false | true  | :non_member | 200
    :private  | :enabled | false | true  | :guest      | 200
    :private  | :enabled | false | true  | :reporter   | 200
    :private  | :enabled | false | true  | :developer  | 200
    :private  | :enabled | false | true  | :maintainer | 200

    :private  | :enabled | false | false | nil         | 404
    :private  | :enabled | false | false | :non_member | 404
    :private  | :enabled | false | false | :guest      | 403
    :private  | :enabled | false | false | :reporter   | 200
    :private  | :enabled | false | false | :developer  | 200
    :private  | :enabled | false | false | :maintainer | 200

    :private  | :private | true  | true  | :non_member | 200
    :private  | :private | true  | true  | :guest      | 200
    :private  | :private | true  | true  | :reporter   | 200
    :private  | :private | true  | true  | :developer  | 200
    :private  | :private | true  | true  | :maintainer | 200

    :private  | :private | true  | false | nil         | 404
    :private  | :private | true  | false | :non_member | 404
    :private  | :private | true  | false | :guest      | 200
    :private  | :private | true  | false | :reporter   | 200
    :private  | :private | true  | false | :developer  | 200
    :private  | :private | true  | false | :maintainer | 200

    :private  | :private | false | true  | :non_member | 200
    :private  | :private | false | true  | :guest      | 200
    :private  | :private | false | true  | :reporter   | 200
    :private  | :private | false | true  | :developer  | 200
    :private  | :private | false | true  | :maintainer | 200

    :private  | :private | false | false | nil         | 404
    :private  | :private | false | false | :non_member | 404
    :private  | :private | false | false | :guest      | 403
    :private  | :private | false | false | :reporter   | 200
    :private  | :private | false | false | :developer  | 200
    :private  | :private | false | false | :maintainer | 200

    :internal | :enabled | true  | true  | :non_member | 200
    :internal | :enabled | true  | true  | :guest      | 200
    :internal | :enabled | true  | true  | :reporter   | 200
    :internal | :enabled | true  | true  | :developer  | 200
    :internal | :enabled | true  | true  | :maintainer | 200

    :internal | :enabled | true  | false | nil         | 404
    :internal | :enabled | true  | false | :non_member | 200
    :internal | :enabled | true  | false | :guest      | 200
    :internal | :enabled | true  | false | :reporter   | 200
    :internal | :enabled | true  | false | :developer  | 200
    :internal | :enabled | true  | false | :maintainer | 200

    :internal | :enabled | false | true  | :non_member | 200
    :internal | :enabled | false | true  | :guest      | 200
    :internal | :enabled | false | true  | :reporter   | 200
    :internal | :enabled | false | true  | :developer  | 200
    :internal | :enabled | false | true  | :maintainer | 200

    :internal | :enabled | false | false | nil         | 404
    :internal | :enabled | false | false | :non_member | 403
    :internal | :enabled | false | false | :guest      | 403
    :internal | :enabled | false | false | :reporter   | 200
    :internal | :enabled | false | false | :developer  | 200
    :internal | :enabled | false | false | :maintainer | 200

    :internal | :private | true  | true  | :non_member | 200
    :internal | :private | true  | true  | :guest      | 200
    :internal | :private | true  | true  | :reporter   | 200
    :internal | :private | true  | true  | :developer  | 200
    :internal | :private | true  | true  | :maintainer | 200

    :internal | :private | true  | false | nil         | 404
    :internal | :private | true  | false | :non_member | 403
    :internal | :private | true  | false | :guest      | 200
    :internal | :private | true  | false | :reporter   | 200
    :internal | :private | true  | false | :developer  | 200
    :internal | :private | true  | false | :maintainer | 200

    :internal | :private | false | true  | :non_member | 200
    :internal | :private | false | true  | :guest      | 200
    :internal | :private | false | true  | :reporter   | 200
    :internal | :private | false | true  | :developer  | 200
    :internal | :private | false | true  | :maintainer | 200

    :internal | :private | false | false | nil         | 404
    :internal | :private | false | false | :non_member | 403
    :internal | :private | false | false | :guest      | 403
    :internal | :private | false | false | :reporter   | 200
    :internal | :private | false | false | :developer  | 200
    :internal | :private | false | false | :maintainer | 200

    :public   | :enabled | true  | true  | :non_member | 200
    :public   | :enabled | true  | true  | :guest      | 200
    :public   | :enabled | true  | true  | :reporter   | 200
    :public   | :enabled | true  | true  | :developer  | 200
    :public   | :enabled | true  | true  | :maintainer | 200

    :public   | :enabled | true  | false | nil         | 200
    :public   | :enabled | true  | false | :non_member | 200
    :public   | :enabled | true  | false | :guest      | 200
    :public   | :enabled | true  | false | :reporter   | 200
    :public   | :enabled | true  | false | :developer  | 200
    :public   | :enabled | true  | false | :maintainer | 200

    :public   | :enabled | false | true  | :non_member | 200
    :public   | :enabled | false | true  | :guest      | 200
    :public   | :enabled | false | true  | :reporter   | 200
    :public   | :enabled | false | true  | :developer  | 200
    :public   | :enabled | false | true  | :maintainer | 200

    :public   | :enabled | false | false | nil         | 403
    :public   | :enabled | false | false | :non_member | 403
    :public   | :enabled | false | false | :guest      | 403
    :public   | :enabled | false | false | :reporter   | 200
    :public   | :enabled | false | false | :developer  | 200
    :public   | :enabled | false | false | :maintainer | 200

    :public   | :private | true  | true  | :non_member | 200
    :public   | :private | true  | true  | :guest      | 200
    :public   | :private | true  | true  | :reporter   | 200
    :public   | :private | true  | true  | :developer  | 200
    :public   | :private | true  | true  | :maintainer | 200

    :public   | :private | true  | false | nil         | 403
    :public   | :private | true  | false | :non_member | 403
    :public   | :private | true  | false | :guest      | 200
    :public   | :private | true  | false | :reporter   | 200
    :public   | :private | true  | false | :developer  | 200
    :public   | :private | true  | false | :maintainer | 200

    :public   | :private | false | true  | :non_member | 200
    :public   | :private | false | true  | :guest      | 200
    :public   | :private | false | true  | :reporter   | 200
    :public   | :private | false | true  | :developer  | 200
    :public   | :private | false | true  | :maintainer | 200

    :public   | :private | false | false | nil         | 403
    :public   | :private | false | false | :non_member | 403
    :public   | :private | false | false | :guest      | 403
    :public   | :private | false | false | :reporter   | 200
    :public   | :private | false | false | :developer  | 200
    :public   | :private | false | false | :maintainer | 200
  end

  with_them do
    before do
      ci_user.update!(admin: is_admin) if user_role

      project.update!(project_attributes)
      project.project_feature.update!(project_feature_attributes)
      project.add_role(ci_user, user_role) if user_role && user_role != :non_member

      get api(pipelines_api_path, api_user, admin_mode: is_admin)
    end

    specify do
      expect(response).to have_gitlab_http_status(response_status)
      expect(api_response).to match(expected_response)
    end
  end
end
