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
      it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://localhost/#{@ci_project.gl_project.path_with_namespace}/commit/2ab7834c/ci")}
    end

    describe "execute" do
      let(:user)    { create(:user, username: 'username') }
      let(:project) { create(:project, name: 'project') }
      let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

      it "calls CreateCommitService" do
        expect_any_instance_of(Ci::CreateCommitService).to receive(:execute).with(@ci_project, user, push_sample_data)

        @service.execute(push_sample_data)
      end
    end
  end
end
