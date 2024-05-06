# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Manual, feature_category: :continuous_integration do
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

      context 'when the job has not been played' do
        it 'instructs the user about possible actions' do
          expect(subject.illustration[:content]).to eq(
            _(
              'This job does not start automatically and must be started manually. ' \
              'You can add CI/CD variables below for last-minute configuration changes before starting the job.'
            )
          )
        end
      end

      context 'when the job is retryable' do
        before do
          job.update!(status: :failed)
        end

        it 'instructs the user about possible actions' do
          expect(subject.illustration[:content]).to eq(
            _("You can modify this job's CI/CD variables before running it again.")
          )
        end
      end
    end

    context 'when the user can not trigger the job because of outdated deployment' do
      before do
        allow(job).to receive(:has_outdated_deployment?).and_return(true)
      end

      it { expect(subject.illustration[:content]).to match(/This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run/) }
    end

    context 'when the user can not trigger the job due to another reason' do
      it 'informs the user' do
        expect(subject.illustration[:content]).to eq(
          _("This job does not run automatically and must be started manually, but you do not have access to it.")
        )
      end
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
