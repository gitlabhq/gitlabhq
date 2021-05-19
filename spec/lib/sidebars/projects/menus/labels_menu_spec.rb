# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::LabelsMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to eq false
  end

  describe '#render?' do
    let(:issues_enabled) { true }

    before do
      allow(project).to receive(:issues_enabled?).and_return(issues_enabled)
    end

    context 'when feature flag :sidebar_refactor is enabled' do
      let(:issues_enabled) { false }

      it 'returns false' do
        expect(subject.render?).to be_falsey
      end
    end

    context 'when feature flag :sidebar_refactor is disabled' do
      before do
        stub_feature_flags(sidebar_refactor: false)
      end

      context 'when user can read labels' do
        context 'when issues feature is enabled' do
          it 'returns false' do
            expect(subject.render?).to be_falsey
          end
        end

        context 'when issues feature is disabled' do
          let(:issues_enabled) { false }

          it 'returns true' do
            expect(subject.render?).to be_truthy
          end
        end
      end

      context 'when user cannot read labels' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to be_falsey
        end
      end
    end
  end
end
