require 'spec_helper'

describe Ci::CreateBuildsService, services: true do
  let(:commit) { create(:ci_commit) }
  let(:user) { create(:user) }

  describe '#execute' do
    subject do
      described_class.new.execute(commit, stage, 'master', nil, user, nil, status)
    end

    context 'stubbed .gitlab-ci.yml' do
      let(:stage) { 'test' }
      let(:status) { 'success' }

      it { is_expected.to be_an_instance_of Array }
      it { is_expected.to all(be_an_instance_of Ci::Build) }
    end
  end
end
