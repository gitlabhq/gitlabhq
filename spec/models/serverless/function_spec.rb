# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Serverless::Function do
  let(:project) { create(:project) }
  let(:func) { described_class.new(project, 'test', 'test-ns') }

  it 'has a proper id' do
    expect(func.id).to eql("#{project.id}/test/test-ns")
    expect(func.name).to eql("test")
    expect(func.namespace).to eql("test-ns")
  end

  it 'can decode an identifier' do
    f = described_class.find_by_id("#{project.id}/testfunc/dummy-ns")

    expect(f.name).to eql("testfunc")
    expect(f.namespace).to eql("dummy-ns")
  end
end
