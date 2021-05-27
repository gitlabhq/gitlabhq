# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::NdjsonPipeline do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:klass) do
    Class.new do
      include BulkImports::NdjsonPipeline

      attr_reader :portable

      def initialize(portable)
        @portable = portable
      end
    end
  end

  subject { klass.new(group) }

  it 'marks pipeline as ndjson' do
    expect(klass.ndjson_pipeline?).to eq(true)
  end

  describe '#deep_transform_relation!' do
    it 'transforms relation hash' do
      transformed = subject.deep_transform_relation!({}, 'test', {}) do |key, hash|
        hash.merge(relation_key: key)
      end

      expect(transformed[:relation_key]).to eq('test')
    end

    context 'when subrelations is an array' do
      it 'transforms each element of the array' do
        relation_hash = {
          'key' => 'value',
          'labels' => [
            { 'title' => 'label 1' },
            { 'title' => 'label 2' },
            { 'title' => 'label 3' }
          ]
        }
        relation_definition = { 'labels' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        transformed['labels'].each do |label|
          expect(label[:relation_key]).to eq('group_labels')
        end
      end
    end

    context 'when subrelation is a hash' do
      it 'transforms subrelation hash' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        expect(transformed['label'][:relation_key]).to eq('group_label')
      end
    end

    context 'when subrelation is nil' do
      it 'removes subrelation' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          if key == 'group_label'
            nil
          else
            hash
          end
        end

        expect(transformed['label']).to be_nil
      end
    end
  end

  describe '#relation_class' do
    context 'when relation name is pluralized' do
      it 'returns constantized class' do
        expect(subject.relation_class('MergeRequest::Metrics')).to eq(MergeRequest::Metrics)
      end
    end

    context 'when relation name is singularized' do
      it 'returns constantized class' do
        expect(subject.relation_class('Badge')).to eq(Badge)
      end
    end
  end

  describe '#relation_key_override' do
    context 'when portable is group' do
      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('group_labels')
      end
    end

    context 'when portable is project' do
      subject { klass.new(project) }

      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('project_labels')
      end
    end
  end
end
