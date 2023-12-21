# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profile::EventEntity, feature_category: :user_profile do
  let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { build(:project_empty_repo, group: group) }
  let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:note) { build(:note_on_merge_request, noteable: merge_request, project: project) }

  let(:target_user) { user }
  let(:event) { build(:event, :merged, author: user, project: project, target: merge_request) }
  let(:request) { double(described_class, current_user: user, target_user: target_user) } # rubocop:disable RSpec/VerifiedDoubles
  let(:entity) { described_class.new(event, request: request) }

  subject { entity.as_json }

  before do
    group.add_maintainer(user)
  end

  it 'exposes fields', :aggregate_failures do
    expect(subject[:created_at]).to eq(event.created_at)
    expect(subject[:action]).to eq(event.action)
    expect(subject[:author][:id]).to eq(target_user.id)
    expect(subject[:author][:name]).to eq(target_user.name)
    expect(subject[:author][:username]).to eq(target_user.username)
  end

  context 'for push events' do
    let_it_be(:commit_from) { Gitlab::Git::SHA1_BLANK_SHA }
    let_it_be(:commit_title) { 'My commit' }
    let(:event) { build(:push_event, project: project, author: target_user) }

    it 'exposes ref fields' do
      build(:push_event_payload, event: event, ref_count: 3)

      expect(subject[:ref][:type]).to eq(event.ref_type)
      expect(subject[:ref][:count]).to eq(event.ref_count)
      expect(subject[:ref][:name]).to eq(event.ref_name)
      expect(subject[:ref][:path]).to be_nil
      expect(subject[:ref][:is_new]).to be false
      expect(subject[:ref][:is_removed]).to be false
    end

    shared_examples 'returns ref path' do
      specify do
        expect(subject[:ref][:path]).to be_present
      end
    end

    context 'with tag' do
      before do
        allow(project.repository).to receive(:tag_exists?).and_return(true)
        build(:push_event_payload, event: event, ref_type: :tag)
      end

      it_behaves_like 'returns ref path'
    end

    context 'with branch' do
      before do
        allow(project.repository).to receive(:branch_exists?).and_return(true)
        build(:push_event_payload, event: event, ref_type: :branch)
      end

      it_behaves_like 'returns ref path'
    end

    it 'exposes commit fields' do
      build(:push_event_payload, event: event, commit_title: commit_title, commit_from: commit_from, commit_count: 2)

      compare_path = "/#{group.path}/#{project.path}/-/compare/#{commit_from}...#{event.commit_to}"
      expect(subject[:commit][:compare_path]).to eq(compare_path)
      expect(event.commit_id).to include(subject[:commit][:truncated_sha])
      expect(subject[:commit][:path]).to be_present
      expect(subject[:commit][:title]).to eq(commit_title)
      expect(subject[:commit][:count]).to eq(2)
      expect(commit_from).to include(subject[:commit][:from_truncated_sha])
      expect(event.commit_to).to include(subject[:commit][:to_truncated_sha])
      expect(subject[:commit][:create_mr_path]).to be_nil
    end

    it 'exposes create_mr_path' do
      allow(project).to receive(:default_branch).and_return('main')
      allow(project.repository).to receive(:branch_exists?).and_return(true)
      build(:push_event_payload, event: event, action: :created, commit_from: commit_from, commit_count: 2)

      new_mr_path = "/#{group.path}/#{project.path}/-/merge_requests/new?" \
                    "merge_request%5Bsource_branch%5D=#{event.branch_name}"
      expect(subject[:commit][:create_mr_path]).to eq(new_mr_path)
    end
  end

  context 'for noteable events' do
    let(:event) { build(:event, :commented, project: project, target: note, author: target_user) }

    it 'exposes noteable fields' do
      expect(subject[:noteable][:type]).to eq(note.noteable_type)
      expect(subject[:noteable][:reference_link_text]).to eq(note.noteable.reference_link_text)
      expect(subject[:noteable][:web_url]).to be_present
      expect(subject[:noteable][:first_line_in_markdown]).to be_present
    end
  end

  context 'with target' do
    context 'when target does not responds to :reference_link_text' do
      let(:event) { build(:event, :commented, project: project, target: note, author: target_user) }

      it 'exposes target fields' do
        expect(subject[:target]).not_to include(:reference_link_text)
        expect(subject[:target][:type]).to eq(note.class.to_s)
        expect(subject[:target][:web_url]).to be_present
        expect(subject[:target][:title]).to eq(note.title)
      end
    end

    context 'when target responds to :reference_link_text' do
      it 'exposes reference_link_text' do
        expect(subject[:target][:reference_link_text]).to eq(merge_request.reference_link_text)
      end
    end

    context 'when target is a wiki page' do
      let(:event) { build(:wiki_page_event, :created, project: project, author: target_user) }

      it 'exposes web_url' do
        expect(subject[:target][:web_url]).to be_present
      end
    end

    context 'when target is a work item' do
      let(:incident) { create(:work_item, :incident, author: target_user, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
      let(:event) do
        build(:event, :created, :for_work_item, author: target_user, project: project, target: incident)
      end

      it 'exposes `issue_type`' do
        expect(subject[:target][:issue_type]).to eq('incident')
      end
    end

    context 'when target is an issue' do
      let(:issue) { build_stubbed(:issue, author: target_user, project: project) }
      let(:event) do
        build(:event, :created, author: target_user, project: project, target: issue)
      end

      it 'exposes `issue_type`' do
        expect(subject[:target][:issue_type]).to eq('issue')
      end
    end
  end

  context 'without target' do
    let(:event) do
      build(:event, :destroyed, author: user, project: project, target_type: Milestone.to_s)
    end

    it 'only exposes target.type' do
      expect(subject[:target][:type]).to eq(Milestone.to_s)
      expect(subject[:target]).not_to include(:web_url)
    end
  end

  context 'with resource parent' do
    it 'exposes resource parent fields' do
      resource_parent = event.resource_parent

      expect(subject[:resource_parent][:type]).to eq('project')
      expect(subject[:resource_parent][:full_name]).to eq(resource_parent.full_name)
      expect(subject[:resource_parent][:full_path]).to eq(resource_parent.full_path)
    end
  end

  context 'for private events' do
    let(:event) { build(:event, :merged, author: target_user) }

    context 'when include_private_contributions? is true' do
      let(:target_user) { build(:user, include_private_contributions: true) }

      it 'exposes only created_at, action, and author', :aggregate_failures do
        expect(subject[:created_at]).to eq(event.created_at)
        expect(subject[:action]).to eq('private')
        expect(subject[:author][:id]).to eq(target_user.id)
        expect(subject[:author][:name]).to eq(target_user.name)
        expect(subject[:author][:username]).to eq(target_user.username)

        is_expected.not_to include(:ref, :commit, :target, :resource_parent)
      end
    end

    context 'when include_private_contributions? is false' do
      let(:target_user) { build(:user, include_private_contributions: false) }

      it { is_expected.to be_empty }
    end
  end
end
