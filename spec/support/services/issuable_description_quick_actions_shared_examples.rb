# frozen_string_literal: true

# Specifications for behavior common to all objects with executable attributes.
# It can take a `default_params`.

RSpec.shared_examples 'issuable record that supports quick actions' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:labels) { create_list(:label, 3, project: project) }

  let(:base_params) { { title: 'My issuable title' } }
  let(:params) { base_params.merge(defined?(default_params) ? default_params : {}).merge(example_params) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(assignee)
  end

  before do
    issuable.reload
  end

  context 'with labels in command only' do
    let(:example_params) do
      {
        description: "/label ~#{labels.first.name} ~#{labels.second.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'attaches labels to issuable' do
      expect(issuable.label_ids).to match_array([labels.first.id, labels.second.id])
    end
  end

  context 'with labels in params and command' do
    let(:example_params) do
      {
        label_ids: [labels.second.id],
        description: "/label ~#{labels.first.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'attaches all labels to issuable' do
      expect(issuable.label_ids).to match_array([labels.first.id, labels.second.id])
    end
  end

  context 'with assignee and milestone in command only' do
    let(:example_params) do
      {
        description: %(/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
      }
    end

    it 'assigns and sets milestone to issuable' do
      expect(issuable.assignees).to eq([assignee])
      expect(issuable.milestone).to eq(milestone)
    end
  end
end
