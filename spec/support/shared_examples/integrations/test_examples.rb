# frozen_string_literal: true

RSpec.shared_examples 'tests for integration with pipeline data' do
  it 'tests the integration with pipeline data' do
    create(:ci_empty_pipeline, project: project)
    allow(Gitlab::DataBuilder::Pipeline).to receive(:build).and_return(sample_data)

    expect(integration).to receive(:test).with(sample_data).and_return(success_result)
    expect(subject).to eq(success_result)
  end
end
