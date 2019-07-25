# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::FailedUnmetPrerequisites do
  describe '#illustration' do
    subject { described_class.new(double).illustration }

    it { is_expected.to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    let(:build) { create(:ci_build, :created) }

    subject { described_class.matches?(build, double) }

    context 'when build has not failed' do
      it { is_expected.to be_falsey }
    end

    context 'when build has failed' do
      before do
        build.drop!(failure_reason)
      end

      context 'with unmet prerequisites' do
        let(:failure_reason) { :unmet_prerequisites }

        it { is_expected.to be_truthy }
      end

      context 'with a different error' do
        let(:failure_reason) { :runner_system_failure }

        it { is_expected.to be_falsey }
      end
    end
  end
end
