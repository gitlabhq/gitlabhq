require 'spec_helper'

describe Ci::CreateTriggerRequestService do
  let(:service) { Ci::CreateTriggerRequestService.new }
  let(:gl_project) { create(:project) }
  let(:project) { create(:ci_project, gl_project: gl_project) }
  let(:trigger) { create(:ci_trigger, project: project) }

  before do
    stub_ci_commit_to_return_yaml_file
  end

  describe :execute do
    context 'valid params' do
      subject { service.execute(project, trigger, 'master') }

      it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
      it { expect(subject.builds.first).to be_kind_of(Ci::Build) }
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
