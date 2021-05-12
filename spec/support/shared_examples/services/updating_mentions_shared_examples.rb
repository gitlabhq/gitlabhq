# frozen_string_literal: true

RSpec.shared_examples 'updating mentions' do |service_class|
  let(:service_class)   { service_class }
  let(:mentioned_user)  { create(:user) }
  let(:group_member1)   { create(:user) }
  let(:group_member2)   { create(:user) }
  let(:external_group)  { create(:group, :private) }

  before do
    project.add_developer(mentioned_user)
    group.add_developer(group_member1)
    group.add_developer(group_member2)
  end

  def update_mentionable(opts)
    perform_enqueued_jobs do
      service_class.new(project: project, current_user: user, params: opts).execute(mentionable)
    end

    mentionable.reload
  end

  context 'when mentioning a different user' do
    context 'in title' do
      before do
        update_mentionable(title: "For #{mentioned_user.to_reference}")
      end

      it 'emails only the newly-mentioned user', :sidekiq_might_not_need_inline do
        should_only_email(mentioned_user)
      end
    end

    context 'in description' do
      before do
        update_mentionable(description: "For #{mentioned_user.to_reference}")
      end

      it 'emails only the newly-mentioned user', :sidekiq_might_not_need_inline do
        should_only_email(mentioned_user)
      end
    end
  end

  context 'when mentioning a user and a group with access to' do
    shared_examples 'updating attribute with allowed mentions' do |attribute|
      before do
        update_mentionable(
          { attribute => "For #{group.to_reference}, cc: #{mentioned_user.to_reference}" }
        )
      end

      it 'emails group members', :sidekiq_might_not_need_inline do
        should_email(mentioned_user)
        should_email(group_member1)
        should_email(group_member2)
      end
    end

    shared_examples 'updating attribute with existing group mention' do |attribute|
      before do
        mentionable.update!({ attribute => "FYI: #{group.to_reference}" })
      end

      it 'creates todos for only newly mentioned users' do
        expect do
          update_mentionable(
            { attribute => "For #{group.to_reference}, cc: #{mentioned_user.to_reference}" }
          )
        end.to change { Todo.count }.by(1)
      end
    end

    context 'when group is public' do
      it_behaves_like 'updating attribute with allowed mentions', :title
      it_behaves_like 'updating attribute with allowed mentions', :description
      it_behaves_like 'updating attribute with existing group mention', :title
      it_behaves_like 'updating attribute with existing group mention', :description
    end

    context 'when the group is private' do
      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'updating attribute with allowed mentions', :title
      it_behaves_like 'updating attribute with allowed mentions', :description
      it_behaves_like 'updating attribute with existing group mention', :title
      it_behaves_like 'updating attribute with existing group mention', :description
    end
  end

  context 'when mentioning a user and a group without access to' do
    shared_examples 'updating attribute with not allowed mentions' do |attribute|
      before do
        update_mentionable(
          { attribute => "For #{external_group.to_reference}, cc: #{mentioned_user.to_reference}" }
        )
      end

      it 'emails mentioned user', :sidekiq_might_not_need_inline do
        should_only_email(mentioned_user)
      end
    end

    context 'when the group is private' do
      it_behaves_like 'updating attribute with not allowed mentions', :title
      it_behaves_like 'updating attribute with not allowed mentions', :description
    end
  end
end
