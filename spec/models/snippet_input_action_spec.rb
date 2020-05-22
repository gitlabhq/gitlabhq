# frozen_string_literal: true

require 'spec_helper'

describe SnippetInputAction do
  describe 'validations' do
    using RSpec::Parameterized::TableSyntax

    where(:action, :file_path, :content, :previous_path, :is_valid) do
      'create' | 'foobar'  | 'foobar' | 'foobar' | true
      'move'   | 'foobar'  | 'foobar' | 'foobar' | true
      'delete' | 'foobar'  | 'foobar' | 'foobar' | true
      'update' | 'foobar'  | 'foobar' | 'foobar' | true
      'foo'    | 'foobar'  | 'foobar' | 'foobar' | false
      nil      | 'foobar'  | 'foobar' | 'foobar' | false
      ''       | 'foobar'  | 'foobar' | 'foobar' | false
      'move'   | 'foobar'  | 'foobar' | nil      | false
      'move'   | 'foobar'  | 'foobar' | ''       | false
      'create' | 'foobar'  | nil      | 'foobar' | false
      'create' | 'foobar'  | ''       | 'foobar' | false
      'create' | nil       | 'foobar' | 'foobar' | false
      'create' | ''        | 'foobar' | 'foobar' | false
    end

    with_them do
      subject { described_class.new(action: action, file_path: file_path, content: content, previous_path: previous_path).valid? }

      specify { is_expected.to be is_valid}
    end
  end

  describe '#to_commit_action' do
    let(:action)        { 'create' }
    let(:file_path)     { 'foo' }
    let(:content)       { 'bar' }
    let(:previous_path) { 'previous_path' }
    let(:options)       { { action: action, file_path: file_path, content: content, previous_path: previous_path } }

    subject { described_class.new(options).to_commit_action }

    it 'transforms attributes to commit action' do
      expect(subject).to eq(options.merge(action: action.to_sym))
    end
  end
end
