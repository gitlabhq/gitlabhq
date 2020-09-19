# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueSerializer do
  let_it_be(:resource) { create(:issue) }
  let_it_be(:user) { create(:user) }

  let(:json_entity) do
    described_class.new(current_user: user)
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  context 'non-sidebar issue serialization' do
    let(:serializer) { nil }

    it 'matches issue json schema' do
      expect(json_entity).to match_schema('entities/issue')
    end
  end

  context 'sidebar issue serialization' do
    let(:serializer) { 'sidebar' }

    it 'matches issue_sidebar json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar')
    end
  end

  context 'sidebar extras issue serialization' do
    let(:serializer) { 'sidebar_extras' }

    it 'matches issue_sidebar_extras json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar_extras')
    end
  end

  context 'board issue serialization' do
    let(:serializer) { 'board' }

    it 'matches board issue json schema' do
      expect(json_entity).to match_schema('entities/issue_board')
    end
  end
end
