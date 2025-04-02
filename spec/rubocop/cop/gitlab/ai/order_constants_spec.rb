# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/ai/order_constants'

RSpec.describe RuboCop::Cop::Gitlab::Ai::OrderConstants, feature_category: :dependency_management do
  context 'when not in the expected order' do
    it 'registers an offense when not in alphabetical order' do
      expect_offense(<<~RUBY)
        module Ai
          module Context
            module Dependencies
              module ConfigFiles
                module Constants
                  CONFIG_FILE_CLASSES = [
                  ^^^^^^^^^^^^^^^^^^^^^^^ Order lock files by language (alphabetically), then by precedence. Lock files should appear first before their non-lock file counterparts.
                    ConfigFiles::PythonPoetry,
                    ConfigFiles::CConanPy,
                    ConfigFiles::CConanTxt
                  ].freeze
                end
              end
            end
          end
        end
      RUBY
    end

    it 'registers an offense when the lock file is before the non-lock file' do
      expect_offense(<<~RUBY)
        module Ai
          module Context
            module Dependencies
              module ConfigFiles
                module Constants
                  CONFIG_FILE_CLASSES = [
                  ^^^^^^^^^^^^^^^^^^^^^^^ Order lock files by language (alphabetically), then by precedence. Lock files should appear first before their non-lock file counterparts.
                    ConfigFiles::JavaMaven,
                    ConfigFiles::JavascriptNpm,
                    ConfigFiles::JavascriptNpmLock,
                  ].freeze
                end
              end
            end
          end
        end
      RUBY
    end

    it 'registers an offense when the lock file is after the non-lock file and not in alphabetical order' do
      expect_offense(<<~RUBY)
        module Ai
          module Context
            module Dependencies
              module ConfigFiles
                module Constants
                  CONFIG_FILE_CLASSES = [
                  ^^^^^^^^^^^^^^^^^^^^^^^ Order lock files by language (alphabetically), then by precedence. Lock files should appear first before their non-lock file counterparts.
                    ConfigFiles::JavaMaven,
                    ConfigFiles::KotlinGradle,
                    ConfigFiles::JavascriptNpm,
                    ConfigFiles::JavascriptNpmLock,
                    ConfigFiles::PhpComposerLock,
                    ConfigFiles::PhpComposer,
                  ].freeze
                end
              end
            end
          end
        end
      RUBY
    end
  end
end
