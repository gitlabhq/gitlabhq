# frozen_string_literal: true
require 'spec_helper'

describe Ci::EnqueueBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:ci_build) { create(:ci_build, :created) }

  subject { described_class.new(project, user).execute(ci_build) }

  it 'enqueues the build' do
    subject

    expect(ci_build.pending?).to be_truthy
  end
end
