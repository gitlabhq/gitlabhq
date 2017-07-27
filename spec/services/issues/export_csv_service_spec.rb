require 'spec_helper'

describe Issues::ExportCsvService do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let!(:issue)  { create(:issue, project: project, author: user) }
  let(:subject) { described_class.new(Issue.all) }

  it 'renders csv to string' do
    expect(subject.csv_data).to be_a String
  end

  describe '#email' do
    it 'emails csv' do
      expect{ subject.email(user, project) }.to change(ActionMailer::Base.deliveries, :count)
    end

    it 'renders with a target filesize' do
      expect(subject.csv_builder).to receive(:render).with(described_class::TARGET_FILESIZE)

      subject.email(user, project)
    end
  end

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  context 'includes' do
    let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
    let(:idea_label) { create(:label, project: project, title: 'Idea') }
    let(:feature_label) { create(:label, project: project, title: 'Feature') }

    before do
      issue.update!(milestone: milestone,
                    assignees: [user],
                    description: 'Issue with details',
                    state: :reopened,
                    due_date: DateTime.new(2014, 3, 2),
                    created_at: DateTime.new(2015, 4, 3, 2, 1, 0),
                    updated_at: DateTime.new(2016, 5, 4, 3, 2, 1),
                    closed_at: DateTime.new(2017, 6, 5, 4, 3, 2),
                    labels: [feature_label, idea_label])
    end

    specify 'iid' do
      expect(csv[0]['Issue ID']).to eq issue.iid.to_s
    end

    specify 'url' do
      expect(csv[0]['URL']).to match(/http.*#{project.full_path}.*#{issue.iid}/)
    end

    specify 'title' do
      expect(csv[0]['Title']).to eq issue.title
    end

    specify 'state' do
      expect(csv[0]['State']).to eq 'Open'
    end

    specify 'description' do
      expect(csv[0]['Description']).to eq issue.description
    end

    specify 'author name' do
      expect(csv[0]['Author']).to eq issue.author_name
    end

    specify 'author username' do
      expect(csv[0]['Author Username']).to eq issue.author.username
    end

    specify 'assignee name' do
      expect(csv[0]['Assignee']).to eq user.name
    end

    specify 'assignee username' do
      expect(csv[0]['Assignee Username']).to eq user.username
    end

    specify 'confidential' do
      expect(csv[0]['Confidential']).to eq 'No'
    end

    specify 'milestone' do
      expect(csv[0]['Milestone']).to eq issue.milestone.title
    end

    specify 'labels' do
      expect(csv[0]['Labels']).to eq 'Feature,Idea'
    end

    specify 'due_date' do
      expect(csv[0]['Due Date']).to eq '2014-03-02'
    end

    specify 'created_at' do
      expect(csv[0]['Created At (UTC)']).to eq '2015-04-03 02:01:00'
    end

    specify 'updated_at' do
      expect(csv[0]['Updated At (UTC)']).to eq '2016-05-04 03:02:01'
    end

    specify 'closed_at' do
      expect(csv[0]['Closed At (UTC)']).to eq '2017-06-05 04:03:02'
    end
  end

  context 'with minimal details' do
    it 'renders labels as nil' do
      expect(csv[0]['Labels']).to eq nil
    end
  end

  it 'succeeds when author is non-existent' do
    issue.author_id = 99999999
    issue.save(validate: false)

    expect(csv[0]['Author']).to eq nil
    expect(csv[0]['Author Username']).to eq nil
  end
end
