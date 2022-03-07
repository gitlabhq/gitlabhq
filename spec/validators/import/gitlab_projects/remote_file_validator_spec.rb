# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::RemoteFileValidator, :aggregate_failures do
  let(:validated_class) do
    Class.new do
      include ActiveModel::Validations

      def self.name
        'AClass'
      end

      attr_accessor :content_type, :content_length

      def initialize(content_length:, content_type:)
        @content_type = content_type
        @content_length = content_length
      end
    end
  end

  let(:validated_object) { validated_class.new(content_length: 1.gigabytes, content_type: 'application/gzip') }

  subject { described_class.new }

  it 'does nothing when the oject is valid' do
    subject.validate(validated_object)

    expect(validated_object.errors.full_messages).to be_empty
  end

  context 'content_length validation' do
    it 'is invalid with file too small' do
      validated_object.content_length = nil

      subject.validate(validated_object)

      expect(validated_object.errors.full_messages)
        .to include('Content length is too small (should be at least 1 Byte)')
    end

    it 'is invalid with file too large' do
      validated_object.content_length = (described_class::FILE_SIZE_LIMIT + 1).gigabytes

      subject.validate(validated_object)

      expect(validated_object.errors.full_messages)
        .to include('Content length is too big (should be at most 10 GB)')
    end
  end

  context 'content_type validation' do
    it 'only allows ALLOWED_CONTENT_TYPES as content_type' do
      described_class::ALLOWED_CONTENT_TYPES.each do |content_type|
        validated_object.content_type = content_type
        subject.validate(validated_object)

        expect(validated_object.errors.to_a).to be_empty
      end

      validated_object.content_type = 'unknown'

      subject.validate(validated_object)

      expect(validated_object.errors.full_messages)
        .to include("Content type 'unknown' not allowed. (Allowed: application/gzip, application/x-tar, application/x-gzip)")
    end
  end
end
