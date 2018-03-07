require 'spec_helper'

describe IssueSerializer do
  let(:resource) { create(:issue) }
  let(:user)     { create(:user) }
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

    it 'matches sidebar issue json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar')
    end
  end
end
