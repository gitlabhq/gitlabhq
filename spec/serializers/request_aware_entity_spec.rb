# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequestAwareEntity do
  subject do
    Class.new.include(described_class).new
  end

  it 'includes URL helpers' do
    expect(subject).to respond_to(:namespace_project_path)
  end

  it 'includes method for checking abilities' do
    expect(subject).to respond_to(:can?)
  end

  it 'fetches request from options' do
    expect(subject).to receive(:options)
      .and_return({ request: 'some value' })

    expect(subject.request).to eq 'some value'
  end
end
