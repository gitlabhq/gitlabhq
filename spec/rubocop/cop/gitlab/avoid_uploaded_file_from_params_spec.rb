# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_uploaded_file_from_params'

RSpec.describe RuboCop::Cop::Gitlab::AvoidUploadedFileFromParams do
  subject(:cop) { described_class.new }

  context 'when using UploadedFile.from_params' do
    it 'flags its call' do
      expect_offense(<<~SOURCE)
        UploadedFile.from_params(params)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `UploadedFile` set by `multipart.rb` instead of calling [...]
      SOURCE
    end
  end
end
