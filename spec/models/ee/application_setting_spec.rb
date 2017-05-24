require 'spec_helper'

describe ApplicationSetting do
  let(:setting) { described_class.create_from_defaults }

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
