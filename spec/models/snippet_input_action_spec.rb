# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetInputAction do
  describe 'validations' do
    using RSpec::Parameterized::TableSyntax

    where(:action, :file_path, :content, :previous_path, :allowed_actions, :is_valid, :invalid_field) do
      :create  | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      :move    | 'foobar'  | 'foobar' | 'foo1'   | nil                | true  | nil
      :delete  | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      :update  | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      :foo     | 'foobar'  | 'foobar' | 'foobar' | nil                | false | :action
      'create' | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      'move'   | 'foobar'  | 'foobar' | 'foo1'   | nil                | true  | nil
      'delete' | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      'update' | 'foobar'  | 'foobar' | 'foobar' | nil                | true  | nil
      'foo'    | 'foobar'  | 'foobar' | 'foobar' | nil                | false | :action
      nil      | 'foobar'  | 'foobar' | 'foobar' | nil                | false | :action
      ''       | 'foobar'  | 'foobar' | 'foobar' | nil                | false | :action
      :move    | 'foobar'  | 'foobar' | nil      | nil                | false | :previous_path
      :move    | 'foobar'  | 'foobar' | ''       | nil                | false | :previous_path
      :move    | 'foobar'  | 'foobar' | 'foobar' | nil                | false | :file_path
      :move    | nil       | 'foobar' | 'foobar' | nil                | true  | nil
      :move    | ''        | 'foobar' | 'foobar' | nil                | true  | nil
      :move    | nil       | 'foobar' | 'foo1'   | nil                | true  | nil
      :move    | 'foobar'  | nil      | 'foo1'   | nil                | true  | nil
      :move    | 'foobar'  | ''       | 'foo1'   | nil                | true  | nil
      :create  | 'foobar'  | nil      | 'foobar' | nil                | false | :content
      :create  | 'foobar'  | ''       | 'foobar' | nil                | false | :content
      :create  | nil       | 'foobar' | 'foobar' | nil                | true  | nil
      :create  | ''        | 'foobar' | 'foobar' | nil                | true  | nil
      :update  | 'foobar'  | nil      | 'foobar' | nil                | false | :content
      :update  | 'foobar'  | ''       | 'foobar' | nil                | false | :content
      :update  | 'other'   | 'foobar' | 'foobar' | nil                | false | :file_path
      :update  | 'foobar'  | 'foobar' | nil      | nil                | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | nil                | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | :update            | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | 'update'           | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | [:update]          | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | [:update, :create] | true  | nil
      :update  | 'foobar'  | 'foobar' | ''       | :create            | false | :action
      :update  | 'foobar'  | 'foobar' | ''       | 'create'           | false | :action
      :update  | 'foobar'  | 'foobar' | ''       | [:create]          | false | :action
      :foo     | 'foobar'  | 'foobar' | ''       | :foo               | false | :action
    end

    with_them do
      subject { described_class.new(action: action, file_path: file_path, content: content, previous_path: previous_path, allowed_actions: allowed_actions) }

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

    subject { described_class.new(**options).to_commit_action }

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
