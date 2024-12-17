# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Aws::ConfigurationController, feature_category: :not_owned do # rubocop:disable RSpec/FeatureCategory -- removing code in https://gitlab.com/gitlab-org/gitlab/-/issues/478491
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:url) { project_aws_configuration_path(project) }

  let_it_be(:user_guest) { create(:user, guest_of: project) }
  let_it_be(:user_developer) { create(:user, developer_of: project) }
  let_it_be(:user_maintainer) { create(:user, maintainer_of: project) }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer] }

  context 'when accessed by unauthorized members' do
    it 'returns not found on GET request' do
      unauthorized_members.each do |unauthorized_member|
        sign_in(unauthorized_member)

        get url
        expect_snowplow_event(
          category: 'Projects::Aws::ConfigurationController',
          action: 'error_invalid_user',
          label: nil,
          project: project,
          user: unauthorized_member
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when accessed by authorized members' do
    it 'returns successful' do
      authorized_members.each do |authorized_member|
        sign_in(authorized_member)

        get url

        expect(response).to be_successful
        expect(response).to render_template('projects/aws/configuration/index')
      end
    end

    include_examples 'requires feature flag `cloudseed_aws` enabled' do
      subject { get url }

      let_it_be(:user) { user_maintainer }
    end
  end
end
