# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeMilestoneService do
  [:issue, :merge_request].each do |issuable|
    it_behaves_like 'a milestone events creator' do
      let(:resource) { create(issuable) }
    end
  end
end
