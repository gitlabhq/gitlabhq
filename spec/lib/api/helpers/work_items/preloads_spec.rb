# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::WorkItems::Preloads, feature_category: :portfolio_management do
  # `freeze: false` is required in this spec: the bare helper instance is a non-AR subject that
  # cannot be deep-frozen. Do not convert it to `let_it_be_with_reload`/`refind`.
  let_it_be(:helper, freeze: false) { Class.new.include(API::Helpers).include(described_class).new }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#preload_work_item_policies' do
    it 'preloads the project policies behind the read checks' do
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader).to receive(:new).and_call_original

      helper.preload_work_item_policies([work_item])
    end

    it 'does nothing without a current user' do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader).not_to receive(:new)

      helper.preload_work_item_policies([work_item])
    end

    it 'does nothing for a blank collection' do
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader).not_to receive(:new)

      helper.preload_work_item_policies([])
    end
  end

  describe '#preload_hierarchy_authorization' do
    # Scoped with `.with` so unrelated framework calls to the same preloader (Banzai reference
    # parsing during factory setup) can't satisfy or break these expectations.
    let_it_be(:parent_project) { work_item.project }
    let_it_be_with_reload(:child) { create(:work_item, :task, project: parent_project) }
    let_it_be(:orphan) { create(:work_item) }

    before_all do
      create(:parent_link, work_item: child, work_item_parent: work_item)
    end

    it 'preloads policies for the hierarchy parents' do
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader)
        .to receive(:new).with([parent_project], user).and_call_original

      helper.preload_hierarchy_authorization([child], [:hierarchy])
    end

    it 'does nothing unless the hierarchy feature was requested' do
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader)
        .not_to receive(:new).with([parent_project], user)

      helper.preload_hierarchy_authorization([child], [:labels])
    end

    it 'does nothing without a current user' do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader)
        .not_to receive(:new).with([parent_project], user)

      helper.preload_hierarchy_authorization([child], [:hierarchy])
    end

    it 'does nothing when no work item has a parent' do
      expect(::Preloaders::UserMaxAccessLevelInProjectsPreloader)
        .not_to receive(:new).with([orphan.project], user)

      helper.preload_hierarchy_authorization([orphan], [:hierarchy])
    end
  end
end
