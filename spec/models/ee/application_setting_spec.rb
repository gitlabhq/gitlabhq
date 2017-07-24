require 'spec_helper'

describe ApplicationSetting do
  let(:setting) { described_class.create_from_defaults }

  describe 'validations' do
    it { is_expected.to allow_value(100).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value((Gitlab::Mirror::MIN_DELAY - 1.minute) / 60).for(:mirror_max_delay) }

    it { is_expected.to allow_value(10).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_capacity) }

    it { is_expected.to allow_value(10).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(nil).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(-1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(subject.mirror_max_capacity + 1).for(:mirror_capacity_threshold) }
  end

  describe '#should_check_namespace_plan?' do
    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan_column)
      allow(::Gitlab).to receive(:com?) { gl_com }
    end

    subject { setting.should_check_namespace_plan? }

    context 'when check_namespace_plan true AND on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { true }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when check_namespace_plan true AND NOT on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { false }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when check_namespace_plan false AND on GitLab.com' do
      let(:check_namespace_plan_column) { false }
      let(:gl_com) { true }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end
end
