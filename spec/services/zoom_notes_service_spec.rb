# frozen_string_literal: true

require 'spec_helper'

describe ZoomNotesService do
  describe '#execute' do
    let(:issue) { OpenStruct.new(description: description) }
    let(:project) { Object.new }
    let(:user) { Object.new }
    let(:description) { 'an issue description' }
    let(:old_description) { nil }

    subject { described_class.new(issue, project, user, old_description: old_description) }

    shared_examples 'no notifications' do
      it "doesn't create notifications" do
        expect(SystemNoteService).not_to receive(:zoom_link_added)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    it_behaves_like 'no notifications'

    context 'when the zoom link exists in both description and old_description' do
      let(:description) { 'a changed issue description https://zoom.us/j/123' }
      let(:old_description) { 'an issue description https://zoom.us/j/123' }

      it_behaves_like 'no notifications'
    end

    context "when the zoom link doesn't exist in both description and old_description" do
      let(:description) { 'a changed issue description' }
      let(:old_description) { 'an issue description' }

      it_behaves_like 'no notifications'
    end

    context 'when description == old_description' do
      let(:old_description) { 'an issue description' }

      it_behaves_like 'no notifications'
    end

    context 'when the description contains a zoom link and old_description is nil' do
      let(:description) { 'a changed issue description https://zoom.us/j/123' }

      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    context 'when the zoom link has been added to the description' do
      let(:description) { 'a changed issue description https://zoom.us/j/123' }
      let(:old_description) { 'an issue description' }

      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    context 'when the zoom link has been removed from the description' do
      let(:description) { 'a changed issue description' }
      let(:old_description) { 'an issue description https://zoom.us/j/123' }

      it 'creates a zoom_link_removed notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).to receive(:zoom_link_removed)

        subject.execute
      end
    end
  end
end
