# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ml::Mlflow::Run do
  let_it_be(:candidate) { create(:ml_candidates) }

  subject { described_class.new(candidate).as_json }

  it 'has run key' do
    expect(subject).to have_key(:run)
  end

  it 'has the id' do
    expect(subject[:run][:info][:run_id]).to eq(candidate.iid.to_s)
  end

  it 'data is empty' do
    expect(subject[:run][:data]).to be_empty
  end
end
