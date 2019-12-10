# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'has user mentions' do
  describe '#has_mentions?' do
    context 'when no mentions' do
      it 'returns false' do
        expect(subject.mentioned_users_ids).to be nil
        expect(subject.mentioned_projects_ids).to be nil
        expect(subject.mentioned_groups_ids).to be nil
        expect(subject.has_mentions?).to be false
      end
    end

    context 'when mentioned_users_ids not null' do
      subject { described_class.new(mentioned_users_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end

    context 'when mentioned projects' do
      subject { described_class.new(mentioned_projects_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end

    context 'when mentioned groups' do
      subject { described_class.new(mentioned_groups_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end
  end
end
