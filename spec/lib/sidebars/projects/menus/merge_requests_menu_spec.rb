# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::MergeRequestsMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when repository is not present' do
      let(:project) { build(:project) }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when repository is present' do
      context 'when user can read merge requests' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot read merge requests' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end
  end

  describe '#pill_count' do
    it 'returns zero when there are no open merge requests' do
      expect(subject.pill_count).to eq 0
    end

    it 'memoizes the query' do
      subject.pill_count

      control = ActiveRecord::QueryRecorder.new do
        subject.pill_count
      end

      expect(control.count).to eq 0
    end

    context 'when there are open merge requests' do
      it 'returns the number of open merge requests' do
        create_list(:merge_request, 2, :unique_branches, source_project: project, author: user, state: :opened)
        create(:merge_request, source_project: project, state: :merged)

        expect(subject.pill_count).to eq 2
      end
    end
  end
end
