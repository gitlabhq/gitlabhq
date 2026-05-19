# frozen_string_literal: true

RSpec.shared_examples 'a partition-pruned pipeline association' do |relation_name = :pipeline|
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline) }

  it "routes #{relation_name} through Ci::Pipeline.find_by_id and marks the association loaded" do
    expect(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_call_original

    expect(related_resource.public_send(relation_name)).to eq(pipeline)
    expect(related_resource.association(relation_name).loaded?).to be(true)
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(partitioned_pipeline_association_finder: false)
    end

    it "does not route #{relation_name} through Ci::Pipeline.find_by_id" do
      expect(Ci::Pipeline).not_to receive(:find_by_id)
      related_resource.public_send(relation_name)
    end
  end
end
