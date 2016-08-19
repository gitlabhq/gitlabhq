RSpec.shared_examples 'updating mentions' do |service_class|
  let(:mentioned_user) { create(:user) }
  let(:service_class) { service_class }

  before { project.team << [mentioned_user, :developer] }

  def update_mentionable(opts)
    reset_delivered_emails!

    perform_enqueued_jobs do
      service_class.new(project, user, opts).execute(mentionable)
    end

    mentionable.reload
  end

  context 'in title' do
    before { update_mentionable(title: mentioned_user.to_reference) }

    it 'emails only the newly-mentioned user' do
      should_only_email(mentioned_user)
    end
  end

  context 'in description' do
    before { update_mentionable(description: mentioned_user.to_reference) }

    it 'emails only the newly-mentioned user' do
      should_only_email(mentioned_user)
    end
  end
end
