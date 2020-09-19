# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/avoid_uploaded_file_from_params'

RSpec.describe RuboCop::Cop::Gitlab::AvoidUploadedFileFromParams, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'UploadedFile.from_params' do
    it 'flags its call' do
      expect_offense(<<~SOURCE)
      UploadedFile.from_params(params)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `UploadedFile` set by `multipart.rb` instead of calling `UploadedFile.from_params` directly. See https://docs.gitlab.com/ee/development/uploads.html#how-to-add-a-new-upload-route
      SOURCE
    end
  end
end
