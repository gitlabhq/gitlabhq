# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Utils do
  delegate :to_boolean, :boolean_to_yes_no, :slugify, :random_string, :which,
           :ensure_array_from_string, :to_exclusive_sentence, :bytes_to_megabytes,
           :append_path, :check_path_traversal!, to: :described_class

  describe '.check_path_traversal!' do
    it 'detects path traversal at the start of the string' do
      expect { check_path_traversal!('../foo') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the start of the string, even to just the subdirectory' do
      expect { check_path_traversal!('../') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal in the middle of the string' do
      expect { check_path_traversal!('foo/../../bar') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string when slash-terminates' do
      expect { check_path_traversal!('foo/../') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string' do
      expect { check_path_traversal!('foo/..') }.to raise_error(/Invalid path/)
    end

    it 'does nothing for a safe string' do
      expect(check_path_traversal!('./foo')).to eq('./foo')
    end
  end

  describe '.slugify' do
    {
      'TEST' => 'test',
      'project_with_underscores' => 'project-with-underscores',
      'namespace/project' =>  'namespace-project',
      'a' * 70 => 'a' * 63,
      'test_trailing_' => 'test-trailing'
    }.each do |original, expected|
      it "slugifies #{original} to #{expected}" do
        expect(slugify(original)).to eq(expected)
      end
    end
  end

  describe '.to_exclusive_sentence' do
    it 'calls #to_sentence on the array' do
      array = double

      expect(array).to receive(:to_sentence)

      to_exclusive_sentence(array)
    end

    it 'joins arrays with two elements correctly' do
      array = %w(foo bar)

      expect(to_exclusive_sentence(array)).to eq('foo or bar')
    end

    it 'joins arrays with more than two elements correctly' do
      array = %w(foo bar baz)

      expect(to_exclusive_sentence(array)).to eq('foo, bar, or baz')
    end

    it 'localizes the connector words' do
      array = %w(foo bar baz)

      expect(described_class).to receive(:_).with(' or ').and_return(' <1> ')
      expect(described_class).to receive(:_).with(', or ').and_return(', <2> ')
      expect(to_exclusive_sentence(array)).to eq('foo, bar, <2> baz')
    end
  end

  describe '.nlbr' do
    it 'replaces new lines with <br>' do
      expect(described_class.nlbr("<b>hello</b>\n<i>world</i>".freeze)).to eq("hello<br>world")
    end
  end

  describe '.remove_line_breaks' do
    using RSpec::Parameterized::TableSyntax

    where(:original, :expected) do
      "foo\nbar\nbaz"     | "foobarbaz"
      "foo\r\nbar\r\nbaz" | "foobarbaz"
      "foobar"            | "foobar"
    end

    with_them do
      it "replace line breaks with an empty string" do
        expect(described_class.remove_line_breaks(original)).to eq(expected)
      end
    end
  end

  describe '.to_boolean' do
    it 'accepts booleans' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean(false)).to be(false)
    end

    it 'converts a valid string to a boolean' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean('true')).to be(true)
      expect(to_boolean('YeS')).to be(true)
      expect(to_boolean('t')).to be(true)
      expect(to_boolean('1')).to be(true)
      expect(to_boolean('ON')).to be(true)

      expect(to_boolean('FaLse')).to be(false)
      expect(to_boolean('F')).to be(false)
      expect(to_boolean('NO')).to be(false)
      expect(to_boolean('n')).to be(false)
      expect(to_boolean('0')).to be(false)
      expect(to_boolean('oFF')).to be(false)
    end

    it 'converts an invalid string to nil' do
      expect(to_boolean('fals')).to be_nil
      expect(to_boolean('yeah')).to be_nil
      expect(to_boolean('')).to be_nil
      expect(to_boolean(nil)).to be_nil
    end
  end

  describe '.boolean_to_yes_no' do
    it 'converts booleans to Yes or No' do
      expect(boolean_to_yes_no(true)).to eq('Yes')
      expect(boolean_to_yes_no(false)).to eq('No')
    end
  end

  describe '.random_string' do
    it 'generates a string' do
      expect(random_string).to be_kind_of(String)
    end
  end

  describe '.which' do
    it 'finds the full path to an executable binary' do
      expect(File).to receive(:executable?).with('/bin/sh').and_return(true)

      expect(which('sh', 'PATH' => '/bin')).to eq('/bin/sh')
    end
  end

  describe '.ensure_array_from_string' do
    it 'returns the same array if given one' do
      arr = ['a', 4, true, { test: 1 }]

      expect(ensure_array_from_string(arr)).to eq(arr)
    end

    it 'turns comma-separated strings into arrays' do
      str = 'seven, eight, 9, 10'

      expect(ensure_array_from_string(str)).to eq(%w[seven eight 9 10])
    end
  end

  describe '.bytes_to_megabytes' do
    it 'converts bytes to megabytes' do
      bytes = 1.megabyte

      expect(bytes_to_megabytes(bytes)).to eq(1)
    end
  end

  describe '.append_path' do
    using RSpec::Parameterized::TableSyntax

    where(:host, :path, :result) do
      'http://test/'  | '/foo/bar'  |  'http://test/foo/bar'
      'http://test/'  | '//foo/bar' |  'http://test/foo/bar'
      'http://test//' | '/foo/bar'  |  'http://test/foo/bar'
      'http://test'   | 'foo/bar'   |  'http://test/foo/bar'
      'http://test//' | ''          |  'http://test/'
      'http://test//' | nil         |  'http://test/'
      ''              | '/foo/bar'  |  '/foo/bar'
      nil             | '/foo/bar'  |  '/foo/bar'
    end

    with_them do
      it 'makes sure there is only one slash as path separator' do
        expect(append_path(host, path)).to eq(result)
      end
    end
  end

  describe '.ensure_utf8_size' do
    context 'string is has less bytes than expected' do
      it 'backfills string with null characters' do
        transformed = described_class.ensure_utf8_size('a' * 10, bytes: 32)

        expect(transformed.bytesize).to eq 32
        expect(transformed).to eq(('a' * 10) + ('0' * 22))
      end
    end

    context 'string size is exactly the one that is expected' do
      it 'returns original value' do
        transformed = described_class.ensure_utf8_size('a' * 32, bytes: 32)

        expect(transformed).to eq 'a' * 32
        expect(transformed.bytesize).to eq 32
      end
    end

    context 'when string contains a few multi-byte UTF characters' do
      it 'backfills string with null characters' do
        transformed = described_class.ensure_utf8_size('❤' * 6, bytes: 32)

        expect(transformed).to eq '❤❤❤❤❤❤' + ('0' * 14)
        expect(transformed.bytesize).to eq 32
      end
    end

    context 'when string has multiple multi-byte UTF chars exceeding 32 bytes' do
      it 'truncates string to 32 characters and backfills it if needed' do
        transformed = described_class.ensure_utf8_size('❤' * 18, bytes: 32)

        expect(transformed).to eq(('❤' * 10) + ('0' * 2))
        expect(transformed.bytesize).to eq 32
      end
    end
  end

  describe '.deep_indifferent_access' do
    let(:hash) do
      { "variables" => [{ "key" => "VAR1", "value" => "VALUE2" }] }
    end

    subject { described_class.deep_indifferent_access(hash) }

    it 'allows to access hash keys with symbols' do
      expect(subject[:variables]).to be_a(Array)
    end

    it 'allows to access array keys with symbols' do
      expect(subject[:variables].first[:key]).to eq('VAR1')
    end
  end

  describe '.try_megabytes_to_bytes' do
    context 'when the size can be converted to megabytes' do
      it 'returns the size in megabytes' do
        size = described_class.try_megabytes_to_bytes(1)

        expect(size).to eq(1.megabytes)
      end
    end

    context 'when the size can not be converted to megabytes' do
      it 'returns the input size' do
        size = described_class.try_megabytes_to_bytes('foo')

        expect(size).to eq('foo')
      end
    end
  end

  describe '.string_to_ip_object' do
    it 'returns nil when string is nil' do
      expect(described_class.string_to_ip_object(nil)).to eq(nil)
    end

    it 'returns nil when string is invalid IP' do
      expect(described_class.string_to_ip_object('invalid ip')).to eq(nil)
      expect(described_class.string_to_ip_object('')).to eq(nil)
    end

    it 'returns IP object when string is valid IP' do
      expect(described_class.string_to_ip_object('192.168.1.1')).to eq(IPAddr.new('192.168.1.1'))
      expect(described_class.string_to_ip_object('::ffff:a9fe:a864')).to eq(IPAddr.new('::ffff:a9fe:a864'))
      expect(described_class.string_to_ip_object('[::ffff:a9fe:a864]')).to eq(IPAddr.new('::ffff:a9fe:a864'))
      expect(described_class.string_to_ip_object('127.0.0.0/28')).to eq(IPAddr.new('127.0.0.0/28'))
      expect(described_class.string_to_ip_object('1:0:0:0:0:0:0:0/124')).to eq(IPAddr.new('1:0:0:0:0:0:0:0/124'))
    end
  end
end
