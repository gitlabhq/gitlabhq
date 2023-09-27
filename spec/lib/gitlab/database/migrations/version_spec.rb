# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Version, feature_category: :database do
  let(:test_versions) do
    [
      4,
      5,
      described_class.new(6, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
      7,
      described_class.new(8, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
      described_class.new(9, Gitlab::VersionInfo.parse_from_milestone('10.4'), :regular),
      described_class.new(10, Gitlab::VersionInfo.parse_from_milestone('10.3'), :post),
      described_class.new(11, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular)
    ]
  end

  describe "#<=>" do
    it 'sorts by existence of milestone, then by milestone, then by type, then by timestamp when sorted by version' do
      expect(test_versions.sort.map(&:to_i)).to eq [4, 5, 7, 6, 8, 11, 10, 9]
    end
  end

  describe 'initialize' do
    context 'when the type is :post or :regular' do
      it 'does not raise an error' do
        expect { described_class.new(4, 4, :regular) }.not_to raise_error
        expect { described_class.new(4, 4, :post) }.not_to raise_error
      end
    end

    context 'when the type is anything else' do
      it 'does not raise an error' do
        expect { described_class.new(4, 4, 'foo') }.to raise_error("#{described_class}::InvalidTypeError".constantize)
      end
    end
  end

  describe 'eql?' do
    where(:version1, :version2, :expected_equality) do
      [
        [
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          true
        ],
        [
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.4'), :regular),
          false
        ],
        [
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :post),
          false
        ],
        [
          described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          described_class.new(5, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular),
          false
        ]
      ]
    end

    with_them do
      it 'correctly evaluates deep equality' do
        expect(version1.eql?(version2)).to eq(expected_equality)
      end

      it 'correctly evaluates deep equality using ==' do
        expect(version1 == version2).to eq(expected_equality)
      end
    end
  end

  describe 'type' do
    subject { described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), migration_type) }

    context 'when the migration is regular' do
      let(:migration_type) { :regular }

      it 'correctly identifies the migration type' do
        expect(subject.type).to eq(:regular)
        expect(subject.regular?).to eq(true)
        expect(subject.post_deployment?).to eq(false)
      end
    end

    context 'when the migration is post_deployment' do
      let(:migration_type) { :post }

      it 'correctly identifies the migration type' do
        expect(subject.type).to eq(:post)
        expect(subject.regular?).to eq(false)
        expect(subject.post_deployment?).to eq(true)
      end
    end
  end

  describe 'to_s' do
    subject { described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular) }

    it 'returns the given timestamp value as a string' do
      expect(subject.to_s).to eql('4')
    end
  end

  describe 'hash' do
    subject { described_class.new(4, Gitlab::VersionInfo.parse_from_milestone('10.3'), :regular) }

    let(:expected_hash) { subject.hash }

    it 'deterministically returns a hash of the timestamp, milestone, and type value' do
      3.times do
        expect(subject.hash).to eq(expected_hash)
      end
    end
  end
end
