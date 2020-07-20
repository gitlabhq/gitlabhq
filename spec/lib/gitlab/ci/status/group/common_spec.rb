# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Group::Common do
  subject do
    Gitlab::Ci::Status::Core.new(double, double)
      .extend(described_class)
  end

  it 'does not have action' do
    expect(subject).not_to have_action
  end

  it 'has details' do
    expect(subject).not_to have_details
  end

  it 'has no details_path' do
    expect(subject.details_path).to be_falsy
  end
end
