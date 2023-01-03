# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Manual do
  let_it_be(:user) { create(:user) }
  let_it_be(:job) { create(:ci_build, :manual) }

  subject do
    described_class.new(Gitlab::Ci::Status::Core.new(job, user))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }

    context 'when the user can trigger the job' do
      before do
        job.project.add_maintainer(user)
      end

      it { expect(subject.illustration[:content]).to match /This job requires manual intervention to start/ }
    end

    context 'when the user can not trigger the job because of outdated deployment' do
      before do
        allow(job).to receive(:outdated_deployment?).and_return(true)
      end

      it { expect(subject.illustration[:content]).to match /This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run/ }
    end

    context 'when the user can not trigger the job due to another reason' do
      it { expect(subject.illustration[:content]).to match /This job does not run automatically and must be started manually/ }
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is manual' do
      let(:build) { create(:ci_build, :manual) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not manual' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
