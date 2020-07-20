# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffLineEntity do
  include RepoHelpers

  let(:code) { 'hello world' }
  let(:line) { Gitlab::Diff::Line.new(code, 'new', 1, nil, 1) }
  let(:entity) { described_class.new(line, request: {}) }

  subject { entity.as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :line_code, :type, :old_line, :new_line, :text, :meta_data, :rich_text
    )
  end

  describe '#rich_text' do
    let(:code) { '<h2 onmouseover="alert(2)">Test</h2>' }
    let(:rich_text_value) { nil }

    before do
      line.instance_variable_set(:@rich_text, rich_text_value)
    end

    shared_examples 'escapes html tags' do
      it do
        expect(subject[:rich_text]).to eq html_escape(code)
        expect(subject[:rich_text]).to be_html_safe
      end
    end

    context 'when rich_line is present' do
      let(:rich_text_value) { code }

      it_behaves_like 'escapes html tags'
    end

    context 'when rich_line is not present' do
      it_behaves_like 'escapes html tags'
    end
  end
end
