# frozen_string_literal: true

RSpec.shared_examples 'a correct instrumented metric value' do |params, expected_value|
  let(:time_frame) { params[:time_frame] }
  let(:options) { params[:options] }

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  it 'has correct value' do
    expect(described_class.new(time_frame: time_frame, options: options).value).to eq(expected_value)
  end
end
