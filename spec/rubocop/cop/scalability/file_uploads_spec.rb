# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/scalability/file_uploads'

RSpec.describe RuboCop::Cop::Scalability::FileUploads do
  subject(:cop) { described_class.new }

  let(:message) { 'Do not upload files without workhorse acceleration. Please refer to https://docs.gitlab.com/ee/development/uploads.html' }

  context 'with required params' do
    it 'detects File in types array' do
      expect_offense(<<~PATTERN)
      params do
        requires :certificate, allow_blank: false, types: [String, File]
                                                                   ^^^^ #{message}
      end
      PATTERN
    end

    it 'detects File as type argument' do
      expect_offense(<<~PATTERN)
      params do
        requires :attachment, type: File
                                    ^^^^ #{message}
      end
      PATTERN
    end
  end

  context 'with optional params' do
    it 'detects File in types array' do
      expect_offense(<<~PATTERN)
      params do
        optional :certificate, allow_blank: false, types: [String, File]
                                                                   ^^^^ #{message}
      end
      PATTERN
    end

    it 'detects File as type argument' do
      expect_offense(<<~PATTERN)
      params do
        optional :attachment, type: File
                                    ^^^^ #{message}
      end
      PATTERN
    end
  end
end
