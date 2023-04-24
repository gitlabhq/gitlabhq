# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Formatters::ImageFormatter do
  let(:base_attrs) do
    {
      base_sha: 123,
      start_sha: 456,
      head_sha: 789,
      old_path: 'old_image.png',
      new_path: 'new_image.png',
      position_type: 'image'
    }
  end

  let(:attrs) do
    base_attrs.merge(width: 100, height: 100, x: 1, y: 2)
  end

  it_behaves_like 'position formatter'

  describe '#==' do
    subject { described_class.new(attrs) }

    it { is_expected.to eq(subject) }

    [:width, :height, :x, :y].each do |attr|
      context "with attribute:#{attr}" do
        let(:other_formatter) do
          described_class.new(attrs.merge(attr => 9))
        end

        it { is_expected.not_to eq(other_formatter) }
      end
    end
  end
end
