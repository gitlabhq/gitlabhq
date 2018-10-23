require 'spec_helper'

describe Gitlab::Ci::Status::Build::Scheduled do
  let(:user) { create(:user) }
  let(:project) { create(:project, :stubbed_repository) }
  let(:build) { create(:ci_build, :scheduled, project: project) }
  let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

  subject { described_class.new(status) }

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '#status_tooltip' do
    context 'when scheduled_at is not expired' do
      let(:build) { create(:ci_build, scheduled_at: 1.minute.since, project: project) }

      it 'shows execute_in of the scheduled job' do
        Timecop.freeze(Time.now.change(usec: 0)) do
          expect(subject.status_tooltip).to include('00:01:00')
        end
      end
    end

    context 'when scheduled_at is expired' do
      let(:build) { create(:ci_build, :expired_scheduled, project: project) }

      it 'shows 00:00' do
        Timecop.freeze do
          expect(subject.status_tooltip).to include('00:00')
        end
      end
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is scheduled and scheduled_at is present' do
      let(:build) { create(:ci_build, :expired_scheduled, project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when build is scheduled' do
      let(:build) { create(:ci_build, status: :scheduled, project: project) }

      it { is_expected.to be_falsy }
    end

    context 'when scheduled_at is present' do
      let(:build) { create(:ci_build, scheduled_at: 1.minute.since, project: project) }

      it { is_expected.to be_falsy }
    end
  end
end
