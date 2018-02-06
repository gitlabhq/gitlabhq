require 'spec_helper'

describe Gitlab::Diff::Formatters::ImageFormatter do
  it_behaves_like "position formatter" do
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
  end
end
