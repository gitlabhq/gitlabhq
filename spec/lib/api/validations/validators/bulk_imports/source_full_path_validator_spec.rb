# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::BulkImports::SourceFullPath, feature_category: :importers do
  include ApiValidatorsHelpers
  using RSpec::Parameterized::TableSyntax

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  let(:source_type_params) { { 'source_type' => source_type } }

  context 'when source_type is group_entity' do
    let(:source_type) { 'group_entity' }

    context 'when source_full_path param is invalid' do
      where(:invalid_param) do
        [
          '',
          '?gitlab',
          "Users's something",
          '/source',
          'http:',
          'https:',
          'example.com/?stuff=true',
          'example.com:5000/?stuff=true',
          'http://gitlab.example/gitlab-org/manage/import/gitlab-migration-test',
          'good_for_me!',
          'good_for+you',
          'source/',
          '.source/full/path.'
        ]
      end

      with_them do
        it 'raises a validation error' do
          params = source_type_params.merge('test' => invalid_param)

          expect_validation_error(params)
        end
      end
    end

    context 'when source_full_path param is valid' do
      where(:valid_param) do
        [
          'source',
          'source/full',
          'source/full/path',
          'sou_rce/fu-ll/pa.th',
          'source/full/path---',
          'source/full/..path',
          'domain_namespace',
          'gitlab-migration-test',
          '1-project-path',
          'e-project-path'
        ]
      end

      with_them do
        it 'does not raise a validation error' do
          params = source_type_params.merge('test' => valid_param)

          expect_no_validation_error(params)
        end
      end
    end
  end

  context 'when source_type is project_entity' do
    let(:source_type) { 'project_entity' }

    context 'when source_full_path param is invalid' do
      where(:invalid_param) do
        [
          '',
          '?gitlab',
          "Users's something",
          '/source',
          'http:',
          'https:',
          'example.com/?stuff=true',
          'example.com:5000/?stuff=true',
          'http://gitlab.example/gitlab-org/manage/import/gitlab-migration-test',
          'good_for_me!',
          'good_for+you',
          'source/',
          'source',
          '.source/full./path',
          'domain_namespace',
          'gitlab-migration-test',
          '1-project-path',
          'e-project-path'
        ]
      end

      with_them do
        it 'raises a validation error' do
          params = source_type_params.merge('test' => invalid_param)

          expect_validation_error(params)
        end
      end
    end

    context 'when source_full_path param is valid' do
      where(:valid_param) do
        [
          'source/full',
          'source/full/path',
          'sou_rce/fu-ll/pa.th',
          'source/full/path---',
          'source/full/..path'
        ]
      end

      with_them do
        it 'does not raise a validation error' do
          params = source_type_params.merge('test' => valid_param)

          expect_no_validation_error(params)
        end
      end
    end
  end

  context 'when source_type is invalid' do
    let(:source_type) { '' }

    context 'when source_full_path param is invalid' do
      where(:invalid_param) do
        [
          '',
          '?gitlab',
          "Users's something",
          '/source',
          'http:',
          'https:',
          'example.com/?stuff=true',
          'example.com:5000/?stuff=true',
          'http://gitlab.example/gitlab-org/manage/import/gitlab-migration-test',
          'good_for_me!',
          'good_for+you',
          'source/',
          '.source/full./path',
          'source',
          'source/full',
          'source/full/path',
          'sou_rce/fu-ll/pa.th',
          'domain_namespace',
          'gitlab-migration-test',
          '1-project-path',
          'e-project-path'
        ]
      end

      with_them do
        it 'raises a validation error' do
          params = source_type_params.merge('test' => invalid_param)

          expect_validation_error(params)
        end
      end
    end
  end
end
