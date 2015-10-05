require 'spec_helper'

describe Ci::CreateTriggerRequestService do
  let(:service) { Ci::CreateTriggerRequestService.new }
  let(:project) { FactoryGirl.create :ci_project }
  let(:gl_project) { FactoryGirl.create :project, gitlab_ci_project: project }
  let(:trigger) { FactoryGirl.create :ci_trigger, project: project }

  before do
    stub_ci_commit_to_return_yaml_file
  end

  describe :execute do
    context 'valid params' do
      subject { service.execute(project, trigger, 'master') }

      it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
      it { expect(subject.commit).to be_kind_of(Ci::Commit) }
    end

    context 'no commit for ref' do
      subject { service.execute(project, trigger, 'other-branch') }

      it { expect(subject).to be_nil }
    end

    context 'no builds created' do
      subject { service.execute(project, trigger, 'master') }

      before do
        stub_ci_commit_yaml_file('{}')
        FactoryGirl.create :ci_commit, gl_project: gl_project
      end

      it { expect(subject).to be_nil }
    end
  end
end
