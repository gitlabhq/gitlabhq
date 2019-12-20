# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestSerializer do
  set(:user) { create(:user) }
  set(:resource) { create(:merge_request, description: "Description") }

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

    it 'matches merge_request_sidebar json schema' do
      expect(json_entity).to match_schema('entities/merge_request_sidebar')
    end
  end

  context 'sidebar_extras merge request serialization' do
    let(:serializer) { 'sidebar_extras' }

    it 'matches merge_request_sidebar_extras json schema' do
      expect(json_entity).to match_schema('entities/merge_request_sidebar_extras')
    end
  end

  context 'basic merge request serialization' do
    let(:serializer) { 'basic' }

    it 'matches basic merge request json schema' do
      expect(json_entity).to match_schema('entities/merge_request_basic')
    end
  end

  context 'noteable merge request serialization' do
    let(:serializer) { 'noteable' }

    it 'matches noteable merge request json schema' do
      expect(json_entity).to match_schema('entities/merge_request_noteable')
    end

    context 'when merge_request is locked' do
      let(:resource) { create(:merge_request, :locked, description: "Description") }

      it 'matches noteable merge request json schema' do
        expect(json_entity).to match_schema('entities/merge_request_noteable')
      end
    end

    context 'when project is archived' do
      let(:project) { create(:project, :archived, :repository) }
      let(:resource) { create(:merge_request, source_project: project, target_project: project, description: "Description") }

      it 'matches noteable merge request json schema' do
        expect(json_entity).to match_schema('entities/merge_request_noteable')
      end
    end
  end

  context 'no serializer' do
    let(:serializer) { nil }

    it 'falls back to the widget entity' do
      expect(json_entity).to match_schema('entities/merge_request_widget')
    end
  end
end
