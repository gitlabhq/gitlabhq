# frozen_string_literal: true

require 'spec_helper'

describe BaseContainerService do
  let(:project) { Project.new }
  let(:user) { User.new }

  describe '#initialize' do
    it 'accepts container and current_user' do
      subject = described_class.new(container: project, current_user: user)

      expect(subject.container).to eq(project)
      expect(subject.current_user).to eq(user)
    end

    it 'treats current_user as optional' do
      subject = described_class.new(container: project)

      expect(subject.current_user).to be_nil
    end
  end
end
