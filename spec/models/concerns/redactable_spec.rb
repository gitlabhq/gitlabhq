# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Redactable do
  before do
    stub_commonmark_sourcepos_disabled
  end

  context 'when model is an issue' do
    it_behaves_like 'model with redactable field' do
      let(:model) { create(:issue) }
      let(:field) { :description }
    end
  end

  context 'when model is a merge request' do
    it_behaves_like 'model with redactable field' do
      let(:model) { create(:merge_request) }
      let(:field) { :description }
    end
  end

  context 'when model is a note' do
    it_behaves_like 'model with redactable field' do
      let(:model) { create(:note) }
      let(:field) { :note }
    end
  end

  context 'when model is a snippet' do
    it_behaves_like 'model with redactable field' do
      let(:model) { create(:project_snippet) }
      let(:field) { :description }
    end
  end
end
