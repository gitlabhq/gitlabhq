# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectHookPolicy, feature_category: :webhooks do
  let_it_be(:user) { create(:user) }

  let(:hook) { create(:project_hook) }

  subject(:policy) { described_class.new(user, hook) }

  context 'when the user is not a maintainer' do
    before do
      hook.project.add_developer(user)
    end

    it "cannot read and destroy web-hooks" do
      expect(policy).to be_disallowed(:destroy_web_hook)
    end
  end

  context 'when the user is a maintainer' do
    before do
      hook.project.add_maintainer(user)
    end

    it "can read and destroy web-hooks" do
      expect(policy).to be_allowed(:destroy_web_hook)
    end
  end
end
