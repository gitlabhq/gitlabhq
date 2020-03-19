# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::ChangeMilestoneService do
  it_behaves_like 'a milestone events creator' do
    let(:resource) { create(:issue) }
  end

  it_behaves_like 'a milestone events creator' do
    let(:resource) { create(:merge_request) }
  end
end
