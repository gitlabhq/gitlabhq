# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Context, feature_category: :navigation do
  let(:project) { build(:project) }

  subject { described_class.new(current_user: nil, container: project) }

  it 'sets project attribute reader' do
    expect(subject.project).to eq(project)
  end
end
