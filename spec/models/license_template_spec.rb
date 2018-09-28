require 'spec_helper'

describe LicenseTemplate do
  describe '#content' do
    it 'calls a proc exactly once if provided' do
      lazy = build_template(-> { 'bar' })
      content = lazy.content

      expect(content).to eq('bar')
      expect(content.object_id).to eq(lazy.content.object_id)

      content.replace('foo')
      expect(lazy.content).to eq('foo')
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
    described_class.new(id: 'foo', name: 'foo', category: :Other, content: content)
  end
end
