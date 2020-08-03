# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'file template shared examples' do |filename, file_extension|
  describe '.all' do
    it "strips the #{file_extension} suffix" do
      expect(subject.all.first.name).not_to end_with(file_extension)
    end

    it 'ensures that the template name is used exactly once' do
      all = subject.all.group_by(&:name)
      duplicates = all.select { |_, templates| templates.length > 1 }

      expect(duplicates).to be_empty
    end
  end

  describe '.by_category' do
    it 'returns sorted results' do
      result = described_class.by_category('General')

      expect(result).to eq(result.sort)
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect(subject.find('nonexistent-file')).to be nil
    end

    it 'returns the corresponding object of a valid file' do
      template = subject.find(filename)

      expect(template).to be_a described_class
      expect(template.name).to eq(filename)
    end
  end

  describe '#<=>' do
    it 'sorts lexicographically' do
      one = described_class.new("a.#{file_extension}")
      other = described_class.new("z.#{file_extension}")

      expect(one.<=>(other)).to be(-1)
      expect([other, one].sort).to eq([one, other])
    end
  end
end
