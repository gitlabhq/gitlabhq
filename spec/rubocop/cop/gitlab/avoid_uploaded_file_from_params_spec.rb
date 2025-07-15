# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_uploaded_file_from_params'

RSpec.describe RuboCop::Cop::Gitlab::AvoidUploadedFileFromParams do
  context 'when using UploadedFile.from_params' do
    it 'flags its call' do
      expect_offense(<<~RUBY)
        UploadedFile.from_params(params)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `UploadedFile` set by `multipart.rb` instead of calling [...]
      RUBY
    end
  end
end
