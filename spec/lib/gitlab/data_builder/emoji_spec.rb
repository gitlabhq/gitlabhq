# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Emoji, feature_category: :markdown do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:snippet) { create(:project_snippet, project: project) }
  let(:action) { 'award' }
  let(:data) { described_class.build(award_emoji, user, action) }
  let(:award_emoji) { create(:award_emoji, awardable: awardable) }

  shared_examples 'includes standard data' do
    specify do
      expect(awardable).to receive(:hook_attrs)
      expect(data[:object_attributes]).to have_key(:awarded_on_url)
      expect(data[:object_kind]).to eq('emoji')
      expect(data[:user]).to eq(user.hook_attrs)
    end

    include_examples 'project hook data'
  end

  describe 'when emoji on issue' do
    let(:awardable) { issue }

    it_behaves_like 'includes standard data'

    it 'returns the issue data' do
      expect(awardable).to receive(:hook_attrs)
      expect(data).to have_key(:issue)
    end
  end

  describe 'when emoji on merge request' do
    let(:awardable) { merge_request }

    it_behaves_like 'includes standard data'

    it 'returns the merge request data' do
      expect(awardable).to receive(:hook_attrs)
      expect(data).to have_key(:merge_request)
    end
  end

  describe 'when emoji on snippet' do
    let(:awardable) { snippet }

    it_behaves_like 'includes standard data'

    it 'returns the snippet data' do
      expect(awardable).to receive(:hook_attrs)
      expect(data).to have_key(:project_snippet)
    end
  end

  describe 'when emoji on note' do
    describe 'when note on issue' do
      let(:note) { create(:note, noteable: issue, project: project) }
      let(:awardable) { note }

      it_behaves_like 'includes standard data'

      it 'returns the note and issue data' do
        expect(note.noteable).to receive(:hook_attrs)
        expect(data).to have_key(:note)
        expect(data).to have_key(:issue)
      end
    end

    describe 'when note on merge request' do
      let(:note) { create(:note, noteable: merge_request, project: project) }
      let(:awardable) { note }

      it_behaves_like 'includes standard data'

      it 'returns the note and merge request data' do
        expect(note.noteable).to receive(:hook_attrs)
        expect(data).to have_key(:note)
        expect(data).to have_key(:merge_request)
      end
    end

    describe 'when note on snippet' do
      let(:note) { create(:note, noteable: snippet, project: project) }
      let(:awardable) { note }

      it_behaves_like 'includes standard data'

      it 'returns the note and snippet data' do
        expect(note.noteable).to receive(:hook_attrs)
        expect(data).to have_key(:note)
        expect(data).to have_key(:project_snippet)
      end
    end

    describe 'when note on commit' do
      let(:note) { create(:note_on_commit, project: project) }
      let(:awardable) { note }

      it_behaves_like 'includes standard data'

      it 'returns the note and commit data' do
        expect(note.noteable).to receive(:hook_attrs)
        expect(data).to have_key(:note)
        expect(data).to have_key(:commit)
      end
    end
  end

  describe 'when awardable does not respond to hook_attrs' do
    let(:awardable) { issue }

    it_behaves_like 'includes standard data'

    it 'returns the issue data' do
      allow(award_emoji.awardable).to receive(:respond_to?).with(:hook_attrs).and_return(false)
      expect(Gitlab::AppLogger).to receive(:error).with(
        'Error building payload data for emoji webhook. Issue does not respond to hook_attrs.')

      data
    end
  end
end
