# frozen_string_literal: true

require 'spec_helper'

describe SnippetInputAction do
  describe 'validations' do
    using RSpec::Parameterized::TableSyntax

    where(:action, :file_path, :content, :previous_path, :is_valid, :invalid_field) do
      :create  | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      :move    | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      :delete  | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      :update  | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      :foo     | 'foobar'  | 'foobar' | 'foobar' | false | :action
      'create' | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      'move'   | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      'delete' | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      'update' | 'foobar'  | 'foobar' | 'foobar' | true  | nil
      'foo'    | 'foobar'  | 'foobar' | 'foobar' | false | :action
      nil      | 'foobar'  | 'foobar' | 'foobar' | false | :action
      ''       | 'foobar'  | 'foobar' | 'foobar' | false | :action
      :move    | 'foobar'  | 'foobar' | nil      | false | :previous_path
      :move    | 'foobar'  | 'foobar' | ''       | false | :previous_path
      :create  | 'foobar'  | nil      | 'foobar' | false | :content
      :create  | 'foobar'  | ''       | 'foobar' | false | :content
      :create  | nil       | 'foobar' | 'foobar' | false | :file_path
      :create  | ''        | 'foobar' | 'foobar' | false | :file_path
      :update  | 'foobar'  | nil      | 'foobar' | false | :content
      :update  | 'foobar'  | ''       | 'foobar' | false | :content
      :update  | 'other'   | 'foobar' | 'foobar' | false | :file_path
      :update  | 'foobar'  | 'foobar' | nil      | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | true  | nil
    end

    with_them do
      subject { described_class.new(action: action, file_path: file_path, content: content, previous_path: previous_path) }

      specify do
        expect(subject.valid?).to be is_valid

        unless is_valid
          expect(subject.errors).to include(invalid_field)
        end
      end
    end
  end

  describe '#to_commit_action' do
    let(:action)           { 'create' }
    let(:file_path)        { 'foo' }
    let(:content)          { 'bar' }
    let(:previous_path)    { 'previous_path' }
    let(:options)          { { action: action, file_path: file_path, content: content, previous_path: previous_path } }
    let(:expected_options) { options.merge(action: action.to_sym) }

    subject { described_class.new(options).to_commit_action }

    it 'transforms attributes to commit action' do
      expect(subject).to eq(expected_options)
    end

    context 'action is update' do
      let(:action) { 'update' }

      context 'when previous_path is present' do
        it 'returns the existing previous_path' do
          expect(subject).to eq(expected_options)
        end
      end

      context 'when previous_path is not present' do
        let(:previous_path) { nil }
        let(:expected_options) { options.merge(action: action.to_sym, previous_path: file_path) }

        it 'assigns the file_path to the previous_path' do
          expect(subject).to eq(expected_options)
        end
      end
    end
  end
end
