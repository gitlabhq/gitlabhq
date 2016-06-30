# Specifications for behavior common to all objects with executable attributes.
# It can take a `default_params`.

shared_examples 'new issuable record that supports slash commands' do
  let!(:project) { create(:project) }
  let(:user) { create(:user).tap { |u| project.team << [u, :master] } }
  let(:assignee) { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:labels) { create_list(:label, 3, project: project) }
  let(:base_params) { { title: FFaker::Lorem.sentence(3) } }
  let(:params) { base_params.merge(defined?(default_params) ? default_params : {}).merge(example_params) }
  let(:issuable) { described_class.new(project, user, params).execute }

  context 'with labels in command only' do
    let(:example_params) do
      {
        description: "/label ~#{labels.first.name} ~#{labels.second.name}\n/remove_label ~#{labels.third.name}"
      }
    end

    it 'attaches labels to issuable' do
      expect(issuable).to be_persisted
      expect(issuable.label_ids).to match_array([labels.first.id, labels.second.id])
    end
  end

  context 'with labels in params and command' do
    let(:example_params) do
      {
        label_ids: [labels.second.id],
        description: "/label ~#{labels.first.name}\n/remove_label ~#{labels.third.name}"
      }
    end

    it 'attaches all labels to issuable' do
      expect(issuable).to be_persisted
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
      expect(issuable).to be_persisted
      expect(issuable.assignee).to eq(assignee)
      expect(issuable.milestone).to eq(milestone)
    end
  end

  context 'with assignee and milestone in params and command' do
    let(:example_params) do
      {
        assignee: build_stubbed(:user),
        milestone_id: double(:milestone),
        description: %(/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
      }
    end

    it 'assigns and sets milestone to issuable from command' do
      expect(issuable).to be_persisted
      expect(issuable.assignee).to eq(assignee)
      expect(issuable.milestone).to eq(milestone)
    end
  end

  describe '/close' do
    let(:example_params) do
      {
        description: '/close'
      }
    end

    it 'returns an open issue' do
      expect(issuable).to be_persisted
      expect(issuable).to be_open
    end
  end
end
