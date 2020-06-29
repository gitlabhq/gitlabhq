# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineMessage do
  describe 'validations' do
    subject { described_class.new(pipeline: pipeline, content: content) }

    let(:pipeline) { create(:ci_pipeline) }

    context 'when message content is longer than the limit' do
      let(:content) { 'x' * (described_class::MAX_CONTENT_LENGTH + 1) }

      it 'is truncated with ellipsis' do
        subject.save!

        expect(subject.content).to end_with('x...')
        expect(subject.content.length).to eq(described_class::MAX_CONTENT_LENGTH)
      end
    end

    context 'when message is not present' do
      let(:content) { '' }

      it 'returns an error' do
        expect(subject.save).to be_falsey
        expect(subject.errors[:content]).to be_present
      end
    end

    context 'when message content is valid' do
      let(:content) { 'valid message content' }

      it 'is saved with default error severity' do
        subject.save!

        expect(subject.content).to eq(content)
        expect(subject.severity).to eq('error')
        expect(subject).to be_error
      end

      it 'is persist the defined severity' do
        subject.severity = :warning

        subject.save!

        expect(subject.content).to eq(content)
        expect(subject.severity).to eq('warning')
        expect(subject).to be_warning
      end
    end
  end
end
