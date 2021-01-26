# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Changelog::Template::Compiler do
  def compile(template, data = {})
    Gitlab::Changelog::Template::Compiler.new.compile(template).render(data)
  end

  describe '#compile' do
    it 'compiles an empty template' do
      expect(compile('')).to eq('')
    end

    it 'compiles a template with an undefined variable' do
      expect(compile('{{number}}')).to eq('')
    end

    it 'compiles a template with a defined variable' do
      expect(compile('{{number}}', 'number' => 42)).to eq('42')
    end

    it 'compiles a template with the special "it" variable' do
      expect(compile('{{it}}', 'values' => 10)).to eq({ 'values' => 10 }.to_s)
    end

    it 'compiles a template containing an if statement' do
      expect(compile('{% if foo %}yes{% end %}', 'foo' => true)).to eq('yes')
    end

    it 'compiles a template containing an if/else statement' do
      expect(compile('{% if foo %}yes{% else %}no{% end %}', 'foo' => false))
        .to eq('no')
    end

    it 'compiles a template that iterates over an Array' do
      expect(compile('{% each numbers %}{{it}}{% end %}', 'numbers' => [1, 2, 3]))
        .to eq('123')
    end

    it 'compiles a template that iterates over a Hash' do
      output = compile(
        '{% each pairs %}{{0}}={{1}}{% end %}',
        'pairs' => { 'key' => 'value' }
      )

      expect(output).to eq('key=value')
    end

    it 'compiles a template that iterates over a Hash of Arrays' do
      output = compile(
        '{% each values %}{{key}}{% end %}',
        'values' => [{ 'key' => 'value' }]
      )

      expect(output).to eq('value')
    end

    it 'compiles a template with a variable path' do
      output = compile('{{foo.bar}}', 'foo' => { 'bar' => 10 })

      expect(output).to eq('10')
    end

    it 'compiles a template with a variable path that uses an Array index' do
      output = compile('{{foo.values.1}}', 'foo' => { 'values' => [10, 20] })

      expect(output).to eq('20')
    end

    it 'compiles a template with a variable path that uses a Hash and a numeric index' do
      output = compile('{{foo.1}}', 'foo' => { 'key' => 'value' })

      expect(output).to eq('')
    end

    it 'compiles a template with a variable path that uses an Array and a String based index' do
      output = compile('{{foo.numbers.bla}}', 'foo' => { 'numbers' => [10, 20] })

      expect(output).to eq('')
    end

    it 'ignores ERB tags provided by the user' do
      input = '<% exit %> <%= exit %> <%= foo -%>'

      expect(compile(input)).to eq(input)
    end

    it 'removes newlines introduced by end statements on their own lines' do
      output = compile(<<~TPL, 'foo' => true)
        {% if foo %}
        foo
        {% end %}
      TPL

      expect(output).to eq("foo\n")
    end

    it 'supports escaping of trailing newlines' do
      output = compile(<<~TPL)
        foo \
        bar\
        baz
      TPL

      expect(output).to eq("foo barbaz\n")
    end

    # rubocop: disable Lint/InterpolationCheck
    it 'ignores embedded Ruby expressions' do
      input = '#{exit}'

      expect(compile(input)).to eq(input)
    end
    # rubocop: enable Lint/InterpolationCheck

    it 'ignores ERB tags inside variable tags' do
      input = '{{<%= exit %>}}'

      expect(compile(input)).to eq(input)
    end

    it 'ignores malicious code that tries to escape a variable' do
      input = "{{') ::Kernel.exit # '}}"

      expect(compile(input)).to eq(input)
    end
  end
end
