# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Public Project Pages Access" do
  using RSpec::Parameterized::TableSyntax
  include AccessMatchers

  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :public, pages_access_level: ProjectFeature::ENABLED, namespace: group) }
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

  describe "Project should be public" do
    describe '#public?' do
      subject { project.public? }

      it { is_expected.to be_truthy }
    end
  end

  describe "GET /projects/:id/pages_access" do
    context 'access depends on the level' do
      where(:pages_access_level, :with_user, :expected_result) do
        ProjectFeature::DISABLED   |   "admin"     |  403
        ProjectFeature::DISABLED   |   "owner"     |  403
        ProjectFeature::DISABLED   |   "master"    |  403
        ProjectFeature::DISABLED   |   "developer" |  403
        ProjectFeature::DISABLED   |   "reporter"  |  403
        ProjectFeature::DISABLED   |   "guest"     |  403
        ProjectFeature::DISABLED   |   "user"      |  403
        ProjectFeature::DISABLED   |   nil         |  403
        ProjectFeature::PUBLIC     |   "admin"     |  200
        ProjectFeature::PUBLIC     |   "owner"     |  200
        ProjectFeature::PUBLIC     |   "master"    |  200
        ProjectFeature::PUBLIC     |   "developer" |  200
        ProjectFeature::PUBLIC     |   "reporter"  |  200
        ProjectFeature::PUBLIC     |   "guest"     |  200
        ProjectFeature::PUBLIC     |   "user"      |  200
        ProjectFeature::PUBLIC     |   nil         |  200
        ProjectFeature::ENABLED    |   "admin"     |  200
        ProjectFeature::ENABLED    |   "owner"     |  200
        ProjectFeature::ENABLED    |   "master"    |  200
        ProjectFeature::ENABLED    |   "developer" |  200
        ProjectFeature::ENABLED    |   "reporter"  |  200
        ProjectFeature::ENABLED    |   "guest"     |  200
        ProjectFeature::ENABLED    |   "user"      |  200
        ProjectFeature::ENABLED    |   nil         |  200
        ProjectFeature::PRIVATE    |   "admin"     |  200
        ProjectFeature::PRIVATE    |   "owner"     |  200
        ProjectFeature::PRIVATE    |   "master"    |  200
        ProjectFeature::PRIVATE    |   "developer" |  200
        ProjectFeature::PRIVATE    |   "reporter"  |  200
        ProjectFeature::PRIVATE    |   "guest"     |  200
        ProjectFeature::PRIVATE    |   "user"      |  403
        ProjectFeature::PRIVATE    |   nil         |  403
      end

      with_them do
        before do
          project.project_feature.update!(pages_access_level: pages_access_level)
        end
        it "correct return value" do
          if !with_user.nil?
            user = public_send(with_user)
            get api("/projects/#{project.id}/pages_access", user)
          else
            get api("/projects/#{project.id}/pages_access")
          end

          expect(response).to have_gitlab_http_status(expected_result)
        end
      end
    end
  end
end
