require 'spec_helper'

describe Ci::CreateTriggerRequestService do
  let(:service) { Ci::CreateTriggerRequestService.new }
  let(:project) { FactoryGirl.create :ci_project }
  let(:trigger) { FactoryGirl.create :ci_trigger, project: project }

  describe :execute do
    context 'valid params' do
      subject { service.execute(project, trigger, 'master') }

      before do
        @commit = FactoryGirl.create :ci_commit, project: project
      end

      it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
      it { expect(subject.commit).to eq(@commit) }
    end

    context 'no commit for ref' do
      subject { service.execute(project, trigger, 'other-branch') }

      it { expect(subject).to be_nil }
    end

    context 'no builds created' do
      subject { service.execute(project, trigger, 'master') }

      before do
        FactoryGirl.create :ci_commit_without_jobs, project: project
      end

      it { expect(subject).to be_nil }
    end

    context 'for multiple commits' do
      subject { service.execute(project, trigger, 'master') }

      before do
        @commit1 = FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, project: project
        @commit2 = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, project: project
        @commit3 = FactoryGirl.create :ci_commit, committed_at: 3.hour.ago, project: project
      end

      context 'retries latest one' do
        it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
        it { expect(subject).to be_persisted }
        it { expect(subject.commit).to eq(@commit2) }
      end
    end
  end
end
