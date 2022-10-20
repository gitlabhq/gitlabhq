# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/no_code_coverage_comment'

RSpec.describe RuboCop::Cop::Gitlab::NoCodeCoverageComment do
  let(:msg) { format(described_class::MSG, nocov_comment: nocov_comment) }
  let(:nocov_comment) { ":#{comment_token}:" }

  shared_examples 'nocov check' do
    it 'flags related code comments' do
      expect_offense(<<~RUBY, nocov_token: comment_token, msg: msg)
        # :%{nocov_token}:
          ^^^{nocov_token} %{msg}
        def method
        end
        #:%{nocov_token}:
         ^^^{nocov_token} %{msg}

        def other_method
          if expr
            #  :%{nocov_token}: With some additional comments
               ^^^{nocov_token} %{msg}
            value << line.strip
            #  :%{nocov_token}:
               ^^^{nocov_token} %{msg}
          end
        end
      RUBY
    end

    it 'ignores unrelated comments' do
      expect_no_offenses(<<~RUBY)
        # Other comments are ignored :#{comment_token}:
        #
        # # :#{comment_token}:
      RUBY
    end
  end

  context 'with nocov as default comment token' do
    it_behaves_like 'nocov check' do
      let(:comment_token) { described_class::DEFAULT_COMMENT_TOKEN }
    end
  end

  context 'with configured comment token' do
    it_behaves_like 'nocov check' do
      let(:comment_token) { 'skipit' }

      let(:config) do
        RuboCop::Config.new(
          'Gitlab/NoCodeCoverageComment' => {
            'CommentToken' => comment_token
          }
        )
      end
    end
  end
end
