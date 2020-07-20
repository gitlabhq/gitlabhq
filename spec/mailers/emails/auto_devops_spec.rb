# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AutoDevops do
  include EmailSpec::Matchers

  describe '#auto_devops_disabled_email' do
    let(:owner) { create(:user) }
    let(:namespace) { create(:namespace, owner: owner) }
    let(:project) { create(:project, :repository, :auto_devops) }
    let(:pipeline) { create(:ci_pipeline, :failed, project: project) }

    subject { Notify.autodevops_disabled_email(pipeline, owner.email) }

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'sents email with correct subject' do
      is_expected.to have_subject("#{project.name} | Auto DevOps pipeline was disabled for #{project.name}")
    end

    it 'sents an email to the user' do
      recipient = subject.header[:to].addrs.map(&:address).first

      expect(recipient).to eq(owner.email)
    end

    it 'is sent as GitLab email' do
      sender = subject.header[:from].addrs[0].address

      expect(sender).to match(/gitlab/)
    end
  end
end
