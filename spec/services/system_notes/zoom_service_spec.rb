# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::ZoomService, feature_category: :integrations do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:author)  { create(:user) }

  let(:noteable)      { create(:issue, project: project) }

  let(:service) { described_class.new(noteable: noteable, container: project, author: author) }

  describe '#zoom_link_added' do
    subject { service.zoom_link_added }

    it_behaves_like 'a system note' do
      let(:action) { 'pinned_embed' }
    end

    it 'sets the zoom link added note text' do
      expect(subject.note).to eq('added a Zoom call to this issue')
    end
  end

  describe '#zoom_link_removed' do
    subject { service.zoom_link_removed }

    it_behaves_like 'a system note' do
      let(:action) { 'pinned_embed' }
    end

    it 'sets the zoom link removed note text' do
      expect(subject.note).to eq('removed a Zoom call from this issue')
    end
  end
end
