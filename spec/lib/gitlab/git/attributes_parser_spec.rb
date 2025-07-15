# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::AttributesParser, feature_category: :source_code_management do
  let_it_be(:data) { fixture_file('gitlab/git/gitattributes') }

  subject { described_class.new(data) }

  describe '#attributes' do
    context 'using a path with attributes' do
      it 'returns the attributes as a Hash' do
        expect(subject.attributes('test.txt')).to eq({ 'text' => true })
      end

      it 'returns a Hash containing multiple attributes' do
        expect(subject.attributes('test.sh'))
          .to eq({ 'eol' => 'lf', 'gitlab-language' => 'shell' })
      end

      it 'returns a Hash containing attributes for a file with multiple extensions' do
        expect(subject.attributes('test.haml.html'))
          .to eq({ 'gitlab-language' => 'haml' })
      end

      it 'returns a Hash containing attributes for a file in a directory' do
        expect(subject.attributes('foo/bar.txt')).to eq({ 'foo' => true })
      end

      it 'returns a Hash containing attributes with query string parameters' do
        expect(subject.attributes('foo.cgi'))
          .to eq({ 'key' => 'value?p1=v1&p2=v2' })
      end

      it 'returns a Hash containing the attributes for an absolute path' do
        expect(subject.attributes('/test.txt')).to eq({ 'text' => true })
      end

      it 'returns a Hash containing the attributes when a pattern is defined using an absolute path' do
        # When a path is given without a leading slash it should still match
        # patterns defined with a leading slash.
        expect(subject.attributes('foo.png'))
          .to eq({ 'gitlab-language' => 'png' })

        expect(subject.attributes('/foo.png'))
          .to eq({ 'gitlab-language' => 'png' })
      end

      it 'returns an empty Hash for a defined path without attributes' do
        expect(subject.attributes('bla/bla.txt')).to eq({})
      end

      context 'with matcher "/designs/**"' do
        it 'returns attributes for a file in a directory' do
          expect(subject.attributes("designs/dk.lfs")).to eq({ 'filter' => 'lfs' })
        end

        it 'returns attributes for a file in a nested directory' do
          expect(subject.attributes("designs/issue-1/dk.lfs")).to eq({ 'filter' => 'lfs' })
        end

        it 'does not return attributes when designs is not the root directory' do
          expect(subject.attributes("path/designs/issue-1/dk.lfs")).to eq({})
        end
      end

      context 'when matcher is at the end' do
        it 'returns attributes for a root directory' do
          expect(subject.attributes('Dockerfile.local')).to eq({ 'gitlab-language' => 'dockerfile' })
        end

        it 'returns attributes for a sub directory' do
          expect(subject.attributes('docker/Dockerfile.local')).to eq({ 'gitlab-language' => 'dockerfile' })
        end
      end

      context 'when the "binary" option is set for a path' do
        it 'returns true for the "binary" option' do
          expect(subject.attributes('test.binary')['binary']).to eq(true)
        end

        it 'returns false for the "diff" option' do
          expect(subject.attributes('test.binary')['diff']).to eq(false)
        end
      end
    end

    context 'using a path without any attributes' do
      it 'returns an empty Hash' do
        expect(subject.attributes('test.foo')).to eq({})
      end
    end

    context 'when attributes data is nil' do
      let(:data) { nil }

      it 'returns an empty Hash' do
        expect(subject.attributes('test.foo')).to eq({})
      end
    end

    context 'when attributes data has binary data' do
      let(:data) { "\xFF\xFE*\u0000.\u0000c\u0000s".b }

      it 'returns an empty Hash' do
        expect(subject.attributes('test.foo')).to eq({})
      end
    end
  end

  describe '#patterns' do
    it 'parses a file with entries' do
      expect(subject.patterns).to be_an_instance_of(Hash)
    end

    it 'parses an entry that uses a tab to separate the pattern and attributes' do
      expect(subject.patterns[File.join('**/', '*.md')])
        .to eq({ 'gitlab-language' => 'markdown' })
    end

    it 'stores patterns in reverse order' do
      first = subject.patterns.to_a[0]

      expect(first[0]).to eq(File.join('**/', 'bla/bla.txt'))
    end

    # It's a bit hard to test for something _not_ being processed. As such we'll
    # just test the number of entries.
    it 'ignores any comments and empty lines' do
      expect(subject.patterns.length).to eq(14)
    end
  end

  describe '#parse_attributes' do
    it 'parses a boolean attribute' do
      expect(subject.parse_attributes('text')).to eq({ 'text' => true })
    end

    it 'parses a negated boolean attribute' do
      expect(subject.parse_attributes('-text')).to eq({ 'text' => false })
    end

    it 'parses a key-value pair' do
      expect(subject.parse_attributes('foo=bar')).to eq({ 'foo' => 'bar' })
    end

    it 'parses multiple attributes' do
      input = 'boolean key=value -negated'

      expect(subject.parse_attributes(input))
        .to eq({ 'boolean' => true, 'key' => 'value', 'negated' => false })
    end

    it 'parses attributes with query string parameters' do
      expect(subject.parse_attributes('foo=bar?baz=1'))
        .to eq({ 'foo' => 'bar?baz=1' })
    end
  end

  describe '#each_line' do
    it 'iterates over every line in the attributes file' do
      args = [String] * 18 # the number of lines in the file

      expect { |b| subject.each_line(&b) }.to yield_successive_args(*args)
    end

    context 'unsupported encoding' do
      let(:data) { fixture_file('gitlab/git/gitattributes_invalid') }

      it 'does not yield' do
        expect { |b| subject.each_line(&b) }.not_to yield_control
      end
    end
  end
end
