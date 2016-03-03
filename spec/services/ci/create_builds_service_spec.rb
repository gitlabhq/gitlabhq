require 'spec_helper'

describe Ci::CreateBuildsService, services: true do
  let(:commit) { create(:ci_commit) }
  let(:user) { create(:user) }

  describe '#execute' do
    # Using stubbed .gitlab-ci.yml created in commit factory
    #

    subject do
      described_class.new.execute(commit, 'test', 'master', nil, user, nil, status)
    end

    context 'next builds available' do
      let(:status) { 'success' }

      it { is_expected.to be_an_instance_of Array }
      it { is_expected.to all(be_an_instance_of Ci::Build) }
    end

    context 'builds skipped' do
      let(:status) { 'skipped' }

      it { is_expected.to be_empty }
    end
  end
end
