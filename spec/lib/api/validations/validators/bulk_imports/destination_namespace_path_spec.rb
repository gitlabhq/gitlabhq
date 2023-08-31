# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::BulkImports::DestinationNamespacePath, feature_category: :importers do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'when destination namespace param is valid' do
    it 'raises a validation error', :aggregate_failures do
      expect_validation_error('test' => '?gitlab')
      expect_validation_error('test' => "Users's something")
      expect_validation_error('test' => '/source')
      expect_validation_error('test' => 'http:')
      expect_validation_error('test' => 'https:')
      expect_validation_error('test' => 'example.com/?stuff=true')
      expect_validation_error('test' => 'example.com:5000/?stuff=true')
      expect_validation_error('test' => 'http://gitlab.example/gitlab-org/manage/import/gitlab-migration-test')
      expect_validation_error('test' => 'good_for_me!')
      expect_validation_error('test' => 'good_for+you')
      expect_validation_error('test' => 'source/')
      expect_validation_error('test' => '.source/full./path')
    end
  end

  context 'when destination namespace param is invalid' do
    it 'does not raise a validation error', :aggregate_failures do
      expect_no_validation_error('')
      expect_no_validation_error('test' => '')
      expect_no_validation_error('test' => 'source')
      expect_no_validation_error('test' => 'source/full')
      expect_no_validation_error('test' => 'source/full/path')
      expect_no_validation_error('test' => 'sou_rce/fu-ll/pa.th')
      expect_no_validation_error('test' => 'domain_namespace')
      expect_no_validation_error('test' => 'gitlab-migration-test')
      expect_no_validation_error('test' => '1-project-path')
      expect_no_validation_error('test' => 'e-project-path')
    end
  end
end
