require 'spec_helper'

describe Gitlab::Utils do
  delegate :to_boolean, :boolean_to_yes_no, :slugify, :random_string, :which, :ensure_array_from_string, :bytes_to_megabytes, to: :described_class

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
end
