# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sanitizable do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include Sanitizable

      attribute :id, :integer
      attribute :name, :string
      attribute :description, :string
      attribute :html_body, :string
      attribute :field_with_true_condition, :string
      attribute :field_with_false_condition, :string

      sanitizes! :name, :description
      sanitizes! :field_with_true_condition, if: -> { true }
      sanitizes! :field_with_false_condition, if: -> { false }

      def self.model_name
        ActiveModel::Name.new(self, nil, 'SomeModel')
      end
    end
  end

  let(:input_double_escaped_data) do
    '%2526lt%253Bscript%2526gt%253Balert%25281%2529%2526lt%253B%252Fscript%2526gt%253B'
  end

  let(:input_path_traversal) { 'main../../../../../../api/v4/projects/1/import_project_members/2' }
  let(:input_path_traversal_and_pre_escaped_html) do
    'main../../../../../../api/v4/projects/1/import_project_members/2&lt;script&gt;alert(1)&lt;/script&gt;'
  end

  let(:input_pre_escaped_html) { '&lt;script&gt;alert(1)&lt;/script&gt;' }

  let(:record) { klass.new(id: 1) }

  subject do
    record.assign_attributes(attrs)
    record.validate
    record
  end

  shared_examples 'a sanitizable field' do |field|
    describe field do
      let(:attrs) { { field => input } }
      let(:field_label) { field.to_s.humanize }

      # rubocop:disable Layout/LineLength -- Avoid breaking the one-line table structure
      where(:input, :expected_output, :errors) do
        nil                                             | nil                                             | []
        'hello, world!'                                 | 'hello, world!'                                 | []
        'hello<script>alert(1)</script>'                | 'hello'                                         | []
        '<div>hello&world</div>'                        | ' hello&world '                                 | []
        ref(:input_path_traversal_and_pre_escaped_html) | ref(:input_path_traversal_and_pre_escaped_html) | lazy { ["#{field_label} cannot contain a path traversal component", "#{field_label} cannot contain escaped HTML entities"] }
        ref(:input_double_escaped_data)                 | ref(:input_double_escaped_data)                 | lazy { ["#{field_label} cannot contain escaped components"] }
        ref(:input_path_traversal)                      | ref(:input_path_traversal)                      | lazy { ["#{field_label} cannot contain a path traversal component"] }
        ref(:input_pre_escaped_html)                    | ref(:input_pre_escaped_html)                    | lazy { ["#{field_label} cannot contain escaped HTML entities"] }
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to have_attributes(field => expected_output, errors: match_array(errors)) }
      end
    end
  end

  shared_examples 'a non-sanitizable field' do |field, input|
    describe field do
      let(:attrs) { { field => input } }

      it { is_expected.to have_attributes(field => input, errors: []) }

      it 'has no effect' do
        expect(Sanitize).not_to receive(:fragment)

        subject
      end
    end
  end

  it_behaves_like 'a non-sanitizable field', :id, 1
  it_behaves_like 'a non-sanitizable field', :html_body, 'hello<script>alert(1)</script>'
  it_behaves_like 'a non-sanitizable field', :field_with_false_condition, 'hello<script>alert(1)</script>'

  it_behaves_like 'a sanitizable field', :name
  it_behaves_like 'a sanitizable field', :description
  it_behaves_like 'a sanitizable field', :field_with_true_condition

  context 'when multiple sanitizable fields are invalid' do
    let(:attrs) { { name: input, description: input } }

    subject do
      record.assign_attributes(name: input, description: input)
      record.validate
      record
    end

    # rubocop:disable Layout/LineLength -- Avoid breaking the one-line table structure
    where(:input, :name_errors, :description_errors) do
      ref(:input_pre_escaped_html)                    | ['Name cannot contain escaped HTML entities']                                                   | ['Description cannot contain escaped HTML entities']
      ref(:input_double_escaped_data)                 | ['Name cannot contain escaped components']                                                      | ['Description cannot contain escaped components']
      ref(:input_path_traversal)                      | ['Name cannot contain a path traversal component']                                              | ['Description cannot contain a path traversal component']
      ref(:input_path_traversal_and_pre_escaped_html) | ['Name cannot contain a path traversal component', 'Name cannot contain escaped HTML entities'] | ['Description cannot contain a path traversal component', 'Description cannot contain escaped HTML entities']
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to have_attributes(name: input, description: input) }
      it { is_expected.to have_attributes(errors: match_array(name_errors + description_errors)) }
    end
  end
end
