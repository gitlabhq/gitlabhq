require 'spec_helper'

describe MergeRequestSerializer do
  let(:user) { create(:user) }
  let(:resource) { create(:merge_request) }
  let(:json_entity) do
    described_class.new(current_user: user)
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  context 'widget merge request serialization' do
    let(:serializer) { 'widget' }

    it 'matches issue json schema' do
      expect(json_entity).to match_schema('entities/merge_request_widget')
    end
  end

  context 'sidebar merge request serialization' do
    let(:serializer) { 'sidebar' }

    it 'matches basic merge request json schema' do
      expect(json_entity).to match_schema('entities/merge_request_basic')
    end
  end

  context 'basic merge request serialization' do
    let(:serializer) { 'basic' }

    it 'matches basic merge request json schema' do
      expect(json_entity).to match_schema('entities/merge_request_basic')
    end
  end

  context 'no serializer' do
    let(:serializer) { nil }

    it 'falls back to the widget entity' do
      expect(json_entity).to match_schema('entities/merge_request_widget')
    end
  end
end
