# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::Validation, feature_category: :permissions do
  describe 'PERMISSION_NAME_REGEX' do
    subject(:regex) { described_class::PERMISSION_NAME_REGEX }

    context 'with valid permission names' do
      valid_names = %w[
        read_issue
        create_merge_request
        delete_project
        update_ci_variable
        read_vulnerability_report
      ]

      valid_names.each do |name|
        it "matches '#{name}'" do
          expect(regex).to match(name)
        end
      end
    end

    context 'with valid underscore-prefixed permission names' do
      valid_names = %w[
        _read_authored_issue
        _delete_created_custom_dashboard
      ]

      valid_names.each do |name|
        it "matches '#{name}'" do
          expect(regex).to match(name)
        end
      end
    end

    context 'with invalid permission names' do
      invalid_names = {
        'Read_issue' => 'starts with uppercase',
        'read' => 'single word with no underscore',
        'read_' => 'ends with underscore',
        '_read' => 'underscore prefix with single word',
        'read_issue!' => 'contains special characters',
        'read issue' => 'contains spaces',
        '123_issue' => 'starts with digits',
        '' => 'empty string',
        'read_Issue' => 'contains uppercase in resource',
        '__read_issue' => 'double underscore prefix'
      }

      invalid_names.each do |name, reason|
        it "does not match '#{name}' (#{reason})" do
          expect(regex).not_to match(name)
        end
      end
    end
  end
end
