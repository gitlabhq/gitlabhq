# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::IssuesMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when user can read issues' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot read issues' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when issues feature is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq true
      end
    end

    context 'when issue feature is disabled' do
      it 'returns false' do
        allow(project).to receive(:issues_enabled?).and_return(false)

        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count' do
    it 'returns zero when there are no open issues' do
      expect(subject.pill_count).to eq 0
    end

    it 'memoizes the query' do
      subject.pill_count

      control = ActiveRecord::QueryRecorder.new do
        subject.pill_count
      end

      expect(control.count).to eq 0
    end

    context 'when there are open issues' do
      it 'returns the number of open issues' do
        create_list(:issue, 2, :opened, project: project)
        create(:issue, :closed, project: project)

        expect(subject.pill_count).to eq 2
      end
    end
  end
end
