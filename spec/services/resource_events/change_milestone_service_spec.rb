# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeMilestoneService do
  let_it_be(:timebox) { create(:milestone) }

  let(:created_at_time) { Time.utc(2019, 12, 30) }
  let(:add_timebox_args) { { created_at: created_at_time, old_milestone: nil } }
  let(:remove_timebox_args) { { created_at: created_at_time, old_milestone: timebox } }

  [:issue, :merge_request].each do |issuable|
    it_behaves_like 'timebox(milestone or iteration) resource events creator', ResourceMilestoneEvent do
      let_it_be(:resource) { create(issuable) } # rubocop:disable Rails/SaveBang
    end
  end
end
