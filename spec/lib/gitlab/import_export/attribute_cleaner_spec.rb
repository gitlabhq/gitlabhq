require 'spec_helper'

describe Gitlab::ImportExport::AttributeCleaner, lib: true do
  let(:unsafe_hash) do
    {
      'service_id' => 99,
      'moved_to_id' => 99,
      'namespace_id' => 99,
      'ci_id' => 99,
      'random_project_id' => 99,
      'random_id' => 99,
      'milestone_id' => 99,
      'project_id' => 99,
      'user_id' => 99,
      'random_id_in_the_middle' => 99,
      'notid' => 99
    }
  end

  let(:post_safe_hash) do
    {
      'project_id' => 99,
      'user_id' => 99,
      'random_id_in_the_middle' => 99,
      'notid' => 99
    }
  end

  it 'removes unwanted attributes from the hash' do
    described_class.clean!(relation_hash: unsafe_hash)

    expect(unsafe_hash).to eq(post_safe_hash)
  end
end
