require 'spec_helper'

describe Gitlab::ImportExport::AttributeCleaner do
  let(:relation_class) { double('relation_class').as_null_object }
  let(:unsafe_hash) do
    {
      'id' => 101,
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
    # allow(relation_class).to receive(:attribute_method?).and_return(true)
    parsed_hash = described_class.clean(relation_hash: unsafe_hash, relation_class: relation_class)

    expect(parsed_hash).to eq(post_safe_hash)
  end
end
