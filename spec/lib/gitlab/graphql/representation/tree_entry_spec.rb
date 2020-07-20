# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Representation::TreeEntry do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil, repository)).to be_nil
    end

    it 'returns array of TreeEntry' do
      entries = described_class.decorate(repository.tree.blobs, repository)

      expect(entries.first).to be_a(described_class)
    end
  end
end
