# frozen_string_literal: true

# This shared_example requires the following variables:
# - issue (required)
#
# Usage:
#
#   it_behaves_like 'incident issue' do
#     let(:issue) { ... }
#   end
#
#   include_examples 'incident issue'
RSpec.shared_examples 'incident issue' do
  it 'has incident as issue type' do
    expect(issue.work_item_type.base_type).to eq('incident')
  end
end

# This shared_example requires the following variables:
# - issue (required)
#
# Usage:
#
#   it_behaves_like 'not an incident issue' do
#     let(:issue) { ... }
#   end
#
#   include_examples 'not an incident issue'
RSpec.shared_examples 'not an incident issue' do
  it 'has not incident as issue type' do
    expect(issue.work_item_type.base_type).not_to eq('incident')
  end
end

# This shared example is to test the execution of incident management label services
# For example:
# - IncidentManagement::CreateIncidentSlaExceededLabelService

# It doesn't require any defined variables

RSpec.shared_examples 'incident management label service' do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:user) { Users::Internal.alert_bot }
  let(:service) { described_class.new(project, user) }

  subject(:execute) { service.execute }

  describe 'execute' do
    let(:incident_label_attributes) { described_class::LABEL_PROPERTIES }
    let(:title) { incident_label_attributes[:title] }
    let(:color) { incident_label_attributes[:color] }
    let(:description) { incident_label_attributes[:description] }

    shared_examples 'existing label' do
      it 'returns the existing label' do
        expect { execute }.not_to change { Label.count }

        expect(execute).to be_success
        expect(execute.payload).to eq(label: label)
      end
    end

    shared_examples 'new label' do
      it 'creates a new label' do
        expect { execute }.to change { Label.count }.by(1)

        label = project.reload.labels.last
        expect(execute).to be_success
        expect(execute.payload).to eq(label: label)
        expect(label.title).to eq(title)
        expect(label.color).to be_color(color)
        expect(label.description).to eq(description)
      end
    end

    context 'with predefined project label' do
      it_behaves_like 'existing label' do
        let!(:label) { create(:label, project: project, title: title) }
      end
    end

    context 'with predefined group label' do
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group) }

      it_behaves_like 'existing label' do
        let!(:label) { create(:group_label, group: group, title: title) }
      end
    end

    context 'without label' do
      context 'when user has permissions to create labels' do
        it_behaves_like 'new label'
      end

      context 'when user has no permissions to create labels' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'new label'
      end
    end
  end
end
