# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectTopic do
  let_it_be(:project_topic, reload: true) { create(:project_topic) }

  subject { project_topic }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:topic) }
    it { is_expected.to validate_uniqueness_of(:topic_id).scoped_to(:project_id) }
  end
end
