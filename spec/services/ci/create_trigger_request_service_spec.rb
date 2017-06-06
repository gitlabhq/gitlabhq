require 'spec_helper'

describe Ci::CreateTriggerRequestService, services: true do
  let(:service) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:trigger) { create(:ci_trigger, project: project, owner: owner) }
  let(:owner) { create(:user) }

  before do
    stub_ci_pipeline_to_return_yaml_file

    project.add_developer(owner)
  end

  describe '#execute' do
    context 'valid params' do
      subject { service.execute(project, trigger, 'master') }

      context 'without owner' do
        it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
        it { expect(subject.pipeline).to be_kind_of(Ci::Pipeline) }
        it { expect(subject.pipeline).to be_trigger }
        it { expect(subject.builds.first).to be_kind_of(Ci::Build) }
      end

      context 'with owner' do
        it { expect(subject).to be_kind_of(Ci::TriggerRequest) }
        it { expect(subject.pipeline).to be_kind_of(Ci::Pipeline) }
        it { expect(subject.pipeline).to be_trigger }
        it { expect(subject.pipeline.user).to eq(owner) }
        it { expect(subject.builds.first).to be_kind_of(Ci::Build) }
        it { expect(subject.builds.first.user).to eq(owner) }
      end
    end

    context 'no commit for ref' do
      subject { service.execute(project, trigger, 'other-branch') }

      it { expect(subject.pipeline).not_to be_persisted }
    end

    context 'no builds created' do
      subject { service.execute(project, trigger, 'master') }

      before do
        stub_ci_pipeline_yaml_file('script: { only: [develop], script: hello World }')
      end

      it { expect(subject.pipeline).not_to be_persisted }
    end
  end
end
