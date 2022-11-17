# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::GitRef do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid revision param' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => '4e963fe')
      expect_no_validation_error('test' => 'foo/bar/baz')
      expect_no_validation_error('test' => "heads/fu\303\237")
      expect_no_validation_error('test' => 'a' * 1024)
    end
  end

  context "revision param contains invalid chars" do
    it 'raises a validation error' do
      expect_validation_error('test' => '-4e963fe')
      expect_validation_error('test' => '4e963fe..ed4ef')
      expect_validation_error('test' => '4e96\3fe')
      expect_validation_error('test' => '4e96@3fe')
      expect_validation_error('test' => '4e9@{63fe')
      expect_validation_error('test' => '4e963 fe')
      expect_validation_error('test' => '4e96~3fe')
      expect_validation_error('test' => '^4e963fe')
      expect_validation_error('test' => '4:e963fe')
      expect_validation_error('test' => '4e963fe.')
      expect_validation_error('test' => 'heads/foo..bar')
      expect_validation_error('test' => 'foo/bar/.')
      expect_validation_error('test' => 'heads/v@{ation')
      expect_validation_error('test' => 'refs/heads/foo.')
      expect_validation_error('test' => 'heads/foo\bar')
      expect_validation_error('test' => 'heads/f[/bar')
      expect_validation_error('test' => "heads/foo\t")
      expect_validation_error('test' => "heads/foo\177")
      expect_validation_error('test' => 'a' * 1025)
      expect_validation_error('test' => nil)
      expect_validation_error('test' => '')
    end
  end
end
