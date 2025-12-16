# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::FailedUnmetPrerequisites, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:user) { instance_double(User) }
  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }

  subject(:status) { described_class.new(core_status) }

  describe '#illustration' do
    subject { status.illustration }

    it { is_expected.to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    let(:build) { create(:ci_build, :created, project: project) }

    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build has not failed' do
      it { is_expected.to be false }
    end

    context 'when build has failed' do
      before do
        build.drop!(failure_reason)
      end

      context 'with unmet prerequisites' do
        let(:failure_reason) { :unmet_prerequisites }

        it { is_expected.to be true }
      end

      context 'with a different error' do
        let(:failure_reason) { :runner_system_failure }

        it { is_expected.to be false }
      end
    end
  end
end
