# frozen_string_literal: true

require 'spec_helper'

# This spec checks if state_id column of issues and merge requests
# are being synced on every save.
# It can be removed in the next release. Check https://gitlab.com/gitlab-org/gitlab-ce/issues/51789  for more information.
describe IssuableStates do
  [Issue, MergeRequest].each do |klass|
    it "syncs state_id column when #{klass.model_name.human} gets created" do
      klass.available_states.each do |state, state_id|
        issuable = build(klass.model_name.param_key, state: state.to_s)

        issuable.save!

        expect(issuable.state_id).to eq(state_id)
      end
    end

    it "syncs state_id column when #{klass.model_name.human} gets updated" do
      klass.available_states.each do |state, state_id|
        issuable = create(klass.model_name.param_key, state: state.to_s)

        issuable.update(state: state)

        expect(issuable.state_id).to eq(state_id)
      end
    end
  end
end
