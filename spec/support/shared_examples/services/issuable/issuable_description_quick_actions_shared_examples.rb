# frozen_string_literal: true

# Specifications for behavior common to all objects with executable attributes.
# It can take a `default_params`.

RSpec.shared_examples 'issuable record that does not supports quick actions' do |with_widgets: false|
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:assignee) { create(:user, maintainer_of: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:labels) { create_list(:label, 3, project: project) }

  let(:new_descr) { "some updated description" }
  let(:base_params) { { title: 'My issuable title' } }
  let(:params) { base_params.merge(with_widgets ? { label_ids: example_params.delete(:label_ids) } : example_params) }
  let(:widget_params) do
    with_widgets ? { description_widget: { description: example_params.delete(:description) } } : {}
  end

  before do
    issuable.reload
  end

  context 'with labels in command only' do
    let(:example_params) do
      {
        description: "#{new_descr}\n/label ~#{labels.first.name} ~#{labels.second.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'does not attach labels to issuable' do
      expect(issuable.label_ids).to be_empty
      expect(issuable.description).to eq new_descr
    end
  end

  context 'with labels in params and command' do
    let(:example_params) do
      {
        label_ids: [labels.second.id],
        description: "#{new_descr}\n/label ~#{labels.first.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'does not attach labels to issuable' do
      expect(issuable.label_ids).to be_empty
      expect(issuable.description).to eq new_descr
    end
  end

  context 'with assignee and milestone in command only' do
    let(:example_params) do
      {
        description: %(#{new_descr}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
      }
    end

    it 'does not assign and set milestone to issuable' do
      expect(issuable.assignees).to be_empty
      expect(issuable.milestone).to be_nil
      expect(issuable.description).to eq new_descr
    end
  end
end

RSpec.shared_examples 'issuable record that supports quick actions' do |with_widgets: false|
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:assignee) { create(:user, maintainer_of: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:labels) { create_list(:label, 3, project: project) }

  let(:new_descr) { "some updated description" }
  let(:base_params) { { title: 'My issuable title' } }
  let(:params) { base_params.merge(with_widgets ? { label_ids: example_params.delete(:label_ids) } : example_params) }
  let(:widget_params) do
    with_widgets ? { description_widget: { description: example_params.delete(:description) } } : {}
  end

  before do
    issuable.reload
  end

  context 'with labels in command only' do
    let(:example_params) do
      {
        description: "#{new_descr}\n/label ~#{labels.first.name} ~#{labels.second.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'attaches labels to issuable' do
      expect(issuable.label_ids).to match_array([labels.first.id, labels.second.id])
      expect(issuable.description).to eq new_descr
    end
  end

  context 'with labels in params and command' do
    let(:example_params) do
      {
        label_ids: [labels.second.id],
        description: "#{new_descr}\n/label ~#{labels.first.name}\n/unlabel ~#{labels.third.name}"
      }
    end

    it 'attaches all labels to issuable' do
      expect(issuable.label_ids).to match_array([labels.first.id, labels.second.id])
      expect(issuable.description).to eq new_descr
    end
  end

  context 'with assignee and milestone in command only' do
    let(:example_params) do
      {
        description: %(#{new_descr}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
      }
    end

    it 'assigns and sets milestone to issuable' do
      expect(issuable.assignees).to eq([assignee])
      expect(issuable.description).to eq new_descr
      expect(issuable.milestone).to eq(milestone)
    end
  end
end

RSpec.shared_examples 'issuable record does not run quick actions when not editing description' do |with_widgets: false|
  let(:residual_quick_actions) { "/label ~#{label.name}\n/assign @#{assignee.username}" }
  let(:old_description) { "foo\n#{residual_quick_actions}\nbar" }
  let(:base_params) { { title: 'My issuable title' } }
  let(:params) { base_params.merge(with_widgets ? {} : description_param) }
  let(:widget_params) { with_widgets ? { description_widget: description_param } : {} }

  before do
    updated_issuable.reload
  end

  context 'when no description param is provided' do
    let(:description_param) { {} }

    it 'sanitizes/removes any residual quick actions and does not execute them' do
      expect(updated_issuable.description).to eq "foo\nbar"
      expect(updated_issuable.labels).to be_empty
      expect(updated_issuable.assignees).to be_empty
    end
  end

  context 'when description param is provided' do
    let(:description_param) { { description: "bar\n/react :smile:\nfoo" } }

    it 'executes only quick actions provided in the description param and skips residual quick actions' do
      expect(updated_issuable.description).to eq "bar\nfoo"
      expect(updated_issuable.award_emoji.first.name).to eq 'smile'
      expect(updated_issuable.labels).to be_empty
      expect(updated_issuable.assignees).to be_empty
    end
  end

  context 'when original description is replaced by description containing a residual quick action' do
    let(:description_param) do
      { description: "bar\n/react :smile:\n#{residual_quick_actions}\nfoo" }
    end

    # side-effect of not executing the residual quick actions resulting in a quick action not being executed
    # even if provided by the user when editing the description
    it 'executes only the non residual quick actions even though provided in description param' do
      expect(updated_issuable.description).to eq "bar\nfoo"
      expect(updated_issuable.award_emoji.first.name).to eq 'smile'
      expect(updated_issuable.labels).to be_empty
      expect(updated_issuable.assignees).to be_empty
    end
  end

  context 'when prepending description with new content' do
    let(:description_param) { { description: "bar\n/react :smile:\nfoo\n\n#{old_description}" } }

    it 'executes only the non residual quick actions' do
      expect(updated_issuable.description).to eq "bar\nfoo\n\nfoo\nbar"
      expect(updated_issuable.award_emoji.first.name).to eq 'smile'
      expect(updated_issuable.labels).to be_empty
      expect(updated_issuable.assignees).to be_empty
    end
  end

  context 'when appending description with new content' do
    let(:description_param) { { description: "#{old_description}\n\nbar\n/react :smile:\nfoo" } }

    it 'executes only the non residual quick actions' do
      expect(updated_issuable.description).to eq "foo\nbar\n\nbar\nfoo"
      expect(updated_issuable.award_emoji.first.name).to eq 'smile'
      expect(updated_issuable.labels).to be_empty
      expect(updated_issuable.assignees).to be_empty
    end
  end
end
