require 'spec_helper'

describe Projects::CreateService, '#execute', services: true do
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
    it 'creates git hook from sample' do
      push_rule_sample = create(:push_rule_sample)

      push_rule = create_project(user, opts).push_rule

      [:force_push_regex, :deny_delete_tag, :delete_branch_regex, :commit_message_regex].each do |attr_name|
        expect(push_rule.send(attr_name)).to eq push_rule_sample.send(attr_name)
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
