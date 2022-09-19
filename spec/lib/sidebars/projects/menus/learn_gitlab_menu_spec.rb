# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::LearnGitlabMenu do
  let_it_be(:project) { build(:project) }
  let_it_be(:learn_gitlab_enabled) { true }

  let(:context) do
    Sidebars::Projects::Context.new(
      current_user: nil,
      container: project,
      learn_gitlab_enabled: learn_gitlab_enabled
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
      let(:learn_gitlab_enabled) { false }

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
      let(:learn_gitlab_enabled) { false }

      it 'returns false' do
        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count' do
    it 'returns pill count' do
      expect_next_instance_of(Onboarding::Completion) do |onboarding|
        expect(onboarding).to receive(:percentage).and_return(20)
      end

      expect(subject.pill_count).to eq '20%'
    end
  end
end
