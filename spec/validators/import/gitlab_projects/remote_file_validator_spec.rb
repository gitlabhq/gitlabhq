# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::RemoteFileValidator, :aggregate_failures, feature_category: :importers do
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

  let(:validated_object) { validated_class.new(content_length: 10.megabytes, content_type: 'application/gzip') }

  subject { described_class.new }

  before do
    stub_application_setting(max_import_remote_file_size: 100)
  end

  it 'does nothing when the object is valid' do
    subject.validate(validated_object)

    expect(validated_object.errors.full_messages).to be_empty
  end

  context 'content_length validation' do
    it 'is invalid with file too small' do
      validated_object.content_length = nil

      subject.validate(validated_object)

      expect(validated_object.errors.full_messages)
        .to include('Content length is too small (should be at least 1 B)')
    end

    it 'is invalid with file too large' do
      validated_object.content_length = 200.megabytes

      subject.validate(validated_object)

      expect(validated_object.errors.full_messages)
        .to include('Content length is too big (should be at most 100 MiB)')
    end

    context 'when max_import_remote_file_size is 0' do
      it 'does not validate file size' do
        stub_application_setting(max_import_remote_file_size: 0)

        validated_object.content_length = 200.megabytes

        subject.validate(validated_object)

        expect(validated_object.errors.full_messages).to be_empty
      end
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
