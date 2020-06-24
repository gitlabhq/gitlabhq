# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target) { create(:milestone, project: project) }
  let_it_be(:group_event) { create(:event, :created, project: nil, group: group, target: target) }
  let_it_be(:project_event) { create(:event, :created, project: project, target: target) }

  describe '#resource_parent_name' do
    context 'with group event' do
      subject { group_event.present.resource_parent_name }

      it { is_expected.to eq(group.full_name) }
    end

    context 'with project label' do
      subject { project_event.present.resource_parent_name }

      it { is_expected.to eq(project.full_name) }
    end
  end

  describe '#target_link_options' do
    context 'with group event' do
      subject { group_event.present.target_link_options }

      it { is_expected.to eq([group, target]) }
    end

    context 'with project label' do
      subject { project_event.present.target_link_options }

      it { is_expected.to eq([group.becomes(Namespace), project, target]) }
    end
  end
end
