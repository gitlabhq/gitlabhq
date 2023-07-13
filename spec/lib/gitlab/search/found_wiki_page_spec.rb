# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::FoundWikiPage, feature_category: :global_search do
  let(:project) { create(:project, :public, :repository) }

  describe 'policy' do
    let(:project) { build(:project, :repository) }
    let(:found_blob) { Gitlab::Search::FoundBlob.new(project: project) }

    subject { described_class.new(found_blob) }

    it 'works with policy' do
      expect(Ability.allowed?(project.creator, :read_wiki_page, subject)).to be_truthy
    end
  end
end
