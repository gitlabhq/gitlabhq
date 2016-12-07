require 'spec_helper'

describe StatusEntity do
  let(:entity) do
    described_class.new(status)
  end

  let(:status) do # TODO, add statuses factory
    Gitlab::Ci::Status::Success.new(double('object'))
  end

  before do
    allow(status).to receive(:has_details?).and_return(true)
    allow(status).to receive(:details_path).and_return('some/path')
  end

  subject { entity.as_json }

  it 'contains status details' do
    expect(subject).to include :text, :icon, :label, :title
    expect(subject).to include :has_details
    expect(subject).to include :details_path
  end
end
