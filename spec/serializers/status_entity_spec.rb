require 'spec_helper'

describe StatusEntity do
  let(:entity) { described_class.new(status) }

  let(:status) do
    Gitlab::Ci::Status::Success.new(double('object'), double('user'))
  end

  before do
    allow(status).to receive(:has_details?).and_return(true)
    allow(status).to receive(:details_path).and_return('some/path')
  end

  subject { entity.as_json }

  it 'contains status details' do
    expect(subject).to include :text, :icon, :label
    expect(subject).to include :has_details
    expect(subject).to include :details_path
  end
end
