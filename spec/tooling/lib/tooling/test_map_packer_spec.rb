# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/test_map_packer'

RSpec.describe Tooling::TestMapPacker do
  subject { described_class.new }

  let(:map) do
    {
      'file1.rb' => [
        './a/b/c/test_1.rb',
        './a/b/test_2.rb',
        './a/b/test_3.rb',
        './a/test_4.rb',
        './test_5.rb'
      ],
      'file2.rb' => [
        './a/b/c/test_1.rb',
        './a/test_4.rb',
        './test_5.rb'
      ]
    }
  end

  let(:compact_map) do
    {
      'file1.rb' => {
        '.' => {
          'a' => {
            'b' => {
              'c' => {
                'test_1.rb' => 1
              },
              'test_2.rb' => 1,
              'test_3.rb' => 1
            },
            'test_4.rb' => 1
          },
          'test_5.rb' => 1
        }
      },
      'file2.rb' => {
        '.' => {
          'a' => {
            'b' => {
              'c' => {
                'test_1.rb' => 1
              }
            },
            'test_4.rb' => 1
          },
          'test_5.rb' => 1
        }
      }
    }
  end

  describe '#pack' do
    it 'compacts list of test files into a prefix tree' do
      expect(subject.pack(map)).to eq(compact_map)
    end

    it 'does nothing to empty hash' do
      expect(subject.pack({})).to eq({})
    end
  end

  describe '#unpack' do
    it 'unpack prefix tree into list of test files' do
      expect(subject.unpack(compact_map)).to eq(map)
    end

    it 'does nothing to empty hash' do
      expect(subject.unpack({})).to eq({})
    end
  end
end
