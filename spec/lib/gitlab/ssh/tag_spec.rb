# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ssh::Tag, feature_category: :source_code_management do
  let_it_be(:project) { create :project, :repository }

  let(:git_tag) { project.repository.tags.first }

  subject(:tag) { described_class.new(project.repository, described_class.context_from_tag(git_tag)) }

  describe '#signature' do
    it 'returns a signature' do
      expect(tag.signature).to be_a_kind_of(Gitlab::Ssh::Signature)
    end
  end
end
