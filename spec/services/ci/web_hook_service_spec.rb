require 'spec_helper'

describe Ci::WebHookService do
  let(:project) { FactoryGirl.create :ci_project }
  let(:gl_project) { FactoryGirl.create :empty_project, gitlab_ci_project: project }
  let(:commit)  { FactoryGirl.create :ci_commit, gl_project: gl_project }
  let(:build)   { FactoryGirl.create :ci_build, commit: commit }
  let(:hook)    { FactoryGirl.create :ci_web_hook, project: project }

  describe :execute do
    it "should execute successfully" do
      stub_request(:post, hook.url).to_return(status: 200)
      expect(Ci::WebHookService.new.build_end(build)).to be_truthy
    end
  end

  context 'build_data' do
    it "contains all needed fields" do
      expect(build_data(build)).to include(
        :build_id,
        :project_id,
        :ref,
        :build_status,
        :build_started_at,
        :build_finished_at,
        :before_sha,
        :project_name,
        :gitlab_url,
        :build_name
      )
    end
  end

  def build_data(build)
    Ci::WebHookService.new.send :build_data, build
  end
end
