# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::ProhibitedAttributesTransformer do
  describe '#transform' do
    let_it_be(:hash) do
      {
        'id' => 101,
        'service_id' => 99,
        'moved_to_id' => 99,
        'namespace_id' => 99,
        'ci_id' => 99,
        'random_project_id' => 99,
        'random_id' => 99,
        'milestone_id' => 99,
        'project_id' => 99,
        'user_id' => 99,
        'random_id_in_the_middle' => 99,
        'notid' => 99,
        'import_source' => 'test',
        'import_type' => 'test',
        'non_existent_attr' => 'test',
        'some_html' => '<p>dodgy html</p>',
        'legit_html' => '<p>legit html</p>',
        '_html' => '<p>perfectly ordinary html</p>',
        'cached_markdown_version' => 12345,
        'custom_attributes' => 'test',
        'some_attributes_metadata' => 'test',
        'group_id' => 99,
        'commit_id' => 99,
        'issue_ids' => [1, 2, 3],
        'merge_request_ids' => [1, 2, 3],
        'note_ids' => [1, 2, 3],
        'remote_attachment_url' => 'http://something.dodgy',
        'remote_attachment_request_header' => 'bad value',
        'remote_attachment_urls' => %w(http://something.dodgy http://something.okay),
        'attributes' => {
          'issue_ids' => [1, 2, 3],
          'merge_request_ids' => [1, 2, 3],
          'note_ids' => [1, 2, 3]
        },
        'variables_attributes' => {
          'id' => 1
        },
        'attr_with_nested_attrs' => {
          'nested_id' => 1,
          'nested_attr' => 2
        }
      }
    end

    let(:expected_hash) do
      {
        'random_id_in_the_middle' => 99,
        'notid' => 99,
        'import_source' => 'test',
        'import_type' => 'test',
        'non_existent_attr' => 'test',
        'attr_with_nested_attrs' => {
          'nested_attr' => 2
        }
      }
    end

    it 'removes prohibited attributes' do
      transformed_hash = subject.transform(nil, hash)

      expect(transformed_hash).to eq(expected_hash)
    end

    context 'when there is no data to transform' do
      it 'returns' do
        expect(subject.transform(nil, nil)).to be_nil
      end
    end
  end
end
