# frozen_string_literal: true

RSpec.shared_examples 'a partition-pruned pipeline association' do |relation_name = :pipeline|
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline) }

  it "routes #{relation_name} through Ci::Pipeline.find_by_id and marks the association loaded" do
    expect(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_call_original

    expect(related_resource.public_send(relation_name)).to eq(pipeline)
    expect(related_resource.association(relation_name).loaded?).to be(true)
  end
end
