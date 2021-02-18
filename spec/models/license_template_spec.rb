# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseTemplate do
  describe '#content' do
    it 'calls a proc exactly once if provided' do
      content_proc = -> { 'bar' }
      expect(content_proc).to receive(:call).once.and_call_original

      lazy = build_template(content_proc)

      expect(lazy.content).to eq('bar')

      # Subsequent calls should not call proc again
      expect(lazy.content).to eq('bar')
    end

    it 'returns a string if provided' do
      lazy = build_template('bar')

      expect(lazy.content).to eq('bar')
    end
  end

  describe '#resolve!' do
    let(:content) do
      <<~TEXT
      Pretend License

      [project]

      Copyright (c) [year] [fullname]
      TEXT
    end

    let(:expected) do
      <<~TEXT
      Pretend License

      Foo Project

      Copyright (c) 1985 Nick Thomas
      TEXT
    end

    let(:template) { build_template(content) }

    it 'updates placeholders in a copy of the template content' do
      expect(template.content.object_id).to eq(content.object_id)

      template.resolve!(project_name: "Foo Project", fullname: "Nick Thomas", year: "1985")

      expect(template.content).to eq(expected)
      expect(template.content.object_id).not_to eq(content.object_id)
    end
  end

  def build_template(content)
    described_class.new(key: 'foo', name: 'foo', project: nil, category: :Other, content: content)
  end
end
