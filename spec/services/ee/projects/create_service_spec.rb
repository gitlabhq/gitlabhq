require 'spec_helper'

describe Projects::CreateService, '#execute' do
  let(:user) { create :user }
  let(:opts) do
    {
      name: "GitLab",
      namespace: user.namespace
    }
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to be_nil
      end
    end
  end

  context 'git hook sample' do
    let!(:sample) { create(:push_rule_sample) }

    subject(:push_rule) { create_project(user, opts).push_rule }

    it 'creates git hook from sample' do
      is_expected.to have_attributes(
        force_push_regex: sample.force_push_regex,
        deny_delete_tag: sample.deny_delete_tag,
        delete_branch_regex: sample.delete_branch_regex,
        commit_message_regex: sample.commit_message_regex
      )
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'ignores the push rule sample' do
        is_expected.to be_nil
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
