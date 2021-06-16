# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::LearnGitlabMenu do
  let_it_be(:project) { build(:project) }
  let_it_be(:experiment_enabled) { true }
  let_it_be(:tracking_category) { 'Growth::Activation::Experiment::LearnGitLabB' }

  let(:context) do
    Sidebars::Projects::Context.new(
      current_user: nil,
      container: project,
      learn_gitlab_experiment_enabled: experiment_enabled,
      learn_gitlab_experiment_tracking_category: tracking_category
    )
  end

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  describe '#nav_link_html_options' do
    let_it_be(:data_tracking) do
      {
        class: 'home',
        data: {
          track_property: tracking_category,
          track_label: 'learn_gitlab'
        }
      }
    end

    specify do
      expect(subject.nav_link_html_options).to eq(data_tracking)
    end
  end

  describe '#render?' do
    context 'when learn gitlab experiment is enabled' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when learn gitlab experiment is disabled' do
      let(:experiment_enabled) { false }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when learn gitlab experiment is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq true
      end
    end

    context 'when learn gitlab experiment is disabled' do
      let(:experiment_enabled) { false }

      it 'returns false' do
        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count' do
    before do
      expect_next_instance_of(LearnGitlab::Onboarding) do |onboarding|
        expect(onboarding).to receive(:completed_percentage).and_return(20)
      end
    end

    it 'returns pill count' do
      expect(subject.pill_count).to eq '20%'
    end
  end
end
