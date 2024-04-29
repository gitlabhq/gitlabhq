# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Stage::PlayManual, feature_category: :continuous_integration do
  let(:stage) { double('stage') }
  let(:play_manual) { described_class.new(stage) }

  describe '#action_icon' do
    subject { play_manual.action_icon }

    it { is_expected.to eq('play') }
  end

  describe '#action_button_title' do
    subject { play_manual.action_button_title }

    it { is_expected.to eq('Run all manual') }
  end

  describe '#action_title' do
    subject { play_manual.action_title }

    it { is_expected.to eq('Run all manual') }
  end

  describe '#action_path' do
    let(:stage) { create(:ci_stage, status: 'manual') }
    let(:pipeline) { stage.pipeline }
    let(:play_manual) { stage.detailed_status(create(:user)) }

    subject { play_manual.action_path }

    it { is_expected.to eq("/#{pipeline.project.full_path}/-/pipelines/#{pipeline.id}/stages/#{stage.name}/play_manual") }
  end

  describe '#action_method' do
    subject { play_manual.action_method }

    it { is_expected.to eq(:post) }
  end

  describe '#confirmation_message' do
    let(:stage) { create(:ci_stage, status: 'manual') }
    let(:play_manual) { stage.detailed_status(create(:user)) }

    subject { play_manual.confirmation_message }

    context 'with manual build' do
      before do
        create(:ci_build, :manual, :with_manual_confirmation, stage_id: stage.id)
      end

      it 'outputs the expected message' do
        is_expected.to eq('This stage has one or more manual jobs that require ' \
                          'confirmation before retrying. Do you want to proceed?')
      end
    end

    context 'without manual build' do
      before do
        create(:ci_build, stage_id: stage.id)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.matches?' do
    let(:user) { double('user') }

    subject { described_class.matches?(stage, user) }

    context 'when stage is skipped' do
      let(:stage) { create(:ci_stage, status: :skipped) }

      it { is_expected.to be_truthy }
    end

    context 'when stage is manual' do
      let(:stage) { create(:ci_stage, status: :manual) }

      it { is_expected.to be_truthy }
    end

    context 'when stage is scheduled' do
      let(:stage) { create(:ci_stage, status: :scheduled) }

      it { is_expected.to be_truthy }
    end

    context 'when stage is success' do
      let(:stage) { create(:ci_stage, status: :success) }

      context 'and does not have manual builds' do
        it { is_expected.to be_falsy }
      end
    end
  end
end
