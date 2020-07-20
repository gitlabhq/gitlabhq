# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AttributesPermitter do
  let(:yml_config) do
    <<-EOF
      tree:
        project:
          - labels:
            - :priorities
          - milestones:
            - events:
              - :push_event_payload

      included_attributes:
        labels:
          - :title
          - :description

      methods:
        labels:
          - :type
    EOF
  end

  let(:file) { Tempfile.new(%w(import_export .yml)) }
  let(:config_hash) { Gitlab::ImportExport::Config.new(config: file.path).to_h }

  before do
    file.write(yml_config)
    file.rewind
  end

  after do
    file.close
    file.unlink
  end

  subject { described_class.new(config: config_hash) }

  describe '#permitted_attributes' do
    it 'builds permitted attributes hash' do
      expect(subject.permitted_attributes).to match(
        a_hash_including(
          project: [:labels, :milestones],
          labels: [:priorities, :title, :description, :type],
          events: [:push_event_payload],
          milestones: [:events],
          priorities: [],
          push_event_payload: []
        )
      )
    end
  end

  describe '#permit' do
    let(:unfiltered_hash) do
      {
        title: 'Title',
        description: 'Description',
        undesired_attribute: 'Undesired Attribute',
        another_attribute: 'Another Attribute'
      }
    end

    it 'only allows permitted attributes' do
      expect(subject.permit(:labels, unfiltered_hash)).to eq(title: 'Title', description: 'Description')
    end
  end

  describe '#permitted_attributes_for' do
    it 'returns an array of permitted attributes for a relation' do
      expect(subject.permitted_attributes_for(:labels)).to contain_exactly(:title, :description, :type, :priorities)
    end
  end
end
