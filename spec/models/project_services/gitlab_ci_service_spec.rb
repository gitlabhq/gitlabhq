# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe GitlabCiService do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:service_hook) }
  end

  describe 'commits methods' do
    before do
      @ci_project = create(:ci_project)
      @service = GitlabCiService.new
      allow(@service).to receive_messages(
        service_hook: true,
        project_url: 'http://ci.gitlab.org/projects/2',
        token: 'verySecret',
        project: @ci_project.gl_project
      )
    end

    describe :build_page do
      it { expect(@service.build_page("2ab7834c", 'master')).to eq("/ci/projects/#{@ci_project.id}/refs/master/commits/2ab7834c")}
      it { expect(@service.build_page("issue#2", 'master')).to eq("/ci/projects/#{@ci_project.id}/refs/master/commits/issue%232")}
    end

    describe "execute" do
      let(:user)    { create(:user, username: 'username') }
      let(:project) { create(:project, name: 'project') }
      let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

      it "calls ci_yaml_file" do
        service_hook = double
        expect(@service).to receive(:ci_yaml_file).with(push_sample_data[:checkout_sha])

        @service.execute(push_sample_data)
      end
    end
  end

  describe "Fork registration" do
    before do
      @old_project = create(:ci_project).gl_project
      @project = create(:empty_project)
      @user = create(:user)

      @service = GitlabCiService.new
      allow(@service).to receive_messages(
        service_hook: true,
        project_url: 'http://ci.gitlab.org/projects/2',
        token: 'verySecret',
        project: @old_project
      )
    end

    it "creates fork on CI" do
      expect_any_instance_of(Ci::CreateProjectService).to receive(:execute)
      @service.fork_registration(@project, @user)
    end
  end
end
