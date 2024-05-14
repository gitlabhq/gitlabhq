# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Private Project Pages Access", feature_category: :pages do
  using RSpec::Parameterized::TableSyntax
  include AccessMatchers

  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :private, pages_access_level: ProjectFeature::ENABLED, namespace: group) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:master) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:access_control).and_return(true)
    group.add_owner(owner)
    project.add_maintainer(master)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
  end

  describe "Project should be private" do
    describe '#private?' do
      subject { project.private? }

      it { is_expected.to be_truthy }
    end
  end

  describe "GET /projects/:id/pages_access" do
    context 'access depends on the level' do
      where(:pages_access_level, :with_user, :admin_mode, :expected_result) do
        ProjectFeature::DISABLED   |   "admin"     | true  |  403
        ProjectFeature::DISABLED   |   "owner"     | false |  403
        ProjectFeature::DISABLED   |   "master"    | false |  403
        ProjectFeature::DISABLED   |   "developer" | false |  403
        ProjectFeature::DISABLED   |   "reporter"  | false |  403
        ProjectFeature::DISABLED   |   "guest"     | false |  403
        ProjectFeature::DISABLED   |   "user"      | false |  404
        ProjectFeature::DISABLED   |   nil         | false |  404
        ProjectFeature::PUBLIC     |   "admin"     | true  |  200
        ProjectFeature::PUBLIC     |   "owner"     | false |  200
        ProjectFeature::PUBLIC     |   "master"    | false |  200
        ProjectFeature::PUBLIC     |   "developer" | false |  200
        ProjectFeature::PUBLIC     |   "reporter"  | false |  200
        ProjectFeature::PUBLIC     |   "guest"     | false |  200
        ProjectFeature::PUBLIC     |   "user"      | false |  404
        ProjectFeature::PUBLIC     |   nil         | false |  404
        ProjectFeature::ENABLED    |   "admin"     | true  |  200
        ProjectFeature::ENABLED    |   "owner"     | false |  200
        ProjectFeature::ENABLED    |   "master"    | false |  200
        ProjectFeature::ENABLED    |   "developer" | false |  200
        ProjectFeature::ENABLED    |   "reporter"  | false |  200
        ProjectFeature::ENABLED    |   "guest"     | false |  200
        ProjectFeature::ENABLED    |   "user"      | false |  404
        ProjectFeature::ENABLED    |   nil         | false |  404
        ProjectFeature::PRIVATE    |   "admin"     | true  |  200
        ProjectFeature::PRIVATE    |   "owner"     | false |  200
        ProjectFeature::PRIVATE    |   "master"    | false |  200
        ProjectFeature::PRIVATE    |   "developer" | false |  200
        ProjectFeature::PRIVATE    |   "reporter"  | false |  200
        ProjectFeature::PRIVATE    |   "guest"     | false |  200
        ProjectFeature::PRIVATE    |   "user"      | false |  404
        ProjectFeature::PRIVATE    |   nil         | false |  404
      end

      with_them do
        before do
          project.project_feature.update!(pages_access_level: pages_access_level)
        end

        it "correct return value" do
          if !with_user.nil?
            user = public_send(with_user)
            get api("/projects/#{project.id}/pages_access", user, admin_mode: admin_mode)
          else
            get api("/projects/#{project.id}/pages_access")
          end

          expect(response).to have_gitlab_http_status(expected_result)
        end
      end
    end
  end
end
