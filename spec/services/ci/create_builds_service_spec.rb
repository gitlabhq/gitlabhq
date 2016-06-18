require 'spec_helper'

describe Ci::CreateBuildsService, services: true do
  let(:pipeline) { create(:ci_pipeline, ref: 'master') }
  let(:user) { create(:user) }

  describe '#execute' do
    # Using stubbed .gitlab-ci.yml created in commit factory
    #

    subject do
      described_class.new(pipeline).execute('test', user, status, nil)
    end

    context 'next builds available' do
      let(:status) { 'success' }

      it { is_expected.to be_an_instance_of Array }
      it { is_expected.to all(be_an_instance_of Ci::Build) }

      it 'does not persist created builds' do
        expect(subject.first).not_to be_persisted
      end
    end

    context 'builds skipped' do
      let(:status) { 'skipped' }

      it { is_expected.to be_empty }
    end
  end
end
