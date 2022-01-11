# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::WaitingForApproval do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(Gitlab::Ci::Status::Core.new(build, user)) }

  describe '#illustration' do
    let(:build) { create(:ci_build, :manual, environment: 'production', project: project) }

    before do
      environment = create(:environment, name: 'production', project: project)
      create(:deployment, :blocked, project: project, environment: environment, deployable: build)
    end

    it { expect(subject.illustration).to include(:image, :size) }
    it { expect(subject.illustration[:title]).to eq('Waiting for approval') }
    it { expect(subject.illustration[:content]).to include('This job deploys to the protected environment "production"') }
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    let(:build) { create(:ci_build, :manual, environment: 'production', project: project) }

    before do
      create(:deployment, deployment_status, deployable: build, project: project)
    end

    context 'when build is waiting for approval' do
      let(:deployment_status) { :blocked }

      it 'is a correct match' do
        expect(subject).to be_truthy
      end
    end

    context 'when build is not waiting for approval' do
      let(:deployment_status) { :created }

      it 'does not match' do
        expect(subject).to be_falsey
      end
    end
  end
end
