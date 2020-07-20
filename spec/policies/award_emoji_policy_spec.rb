# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojiPolicy do
  let(:user) { create(:user) }
  let(:award_emoji) { create(:award_emoji, awardable: awardable) }

  subject { described_class.new(user, award_emoji) }

  shared_examples 'when the user can read the awardable' do
    context do
      let(:project) { create(:project, :public) }

      it { expect_allowed(:read_emoji) }
    end
  end

  shared_examples 'when the user cannot read the awardable' do
    context do
      let(:project) { create(:project, :private) }

      it { expect_disallowed(:read_emoji) }
    end
  end

  context 'when the awardable is an issue' do
    let(:awardable) { create(:issue, project: project) }

    include_examples 'when the user can read the awardable'
    include_examples 'when the user cannot read the awardable'
  end

  context 'when the awardable is a merge request' do
    let(:awardable) { create(:merge_request, source_project: project) }

    include_examples 'when the user can read the awardable'
    include_examples 'when the user cannot read the awardable'
  end

  context 'when the awardable is a note' do
    let(:awardable) { create(:note_on_merge_request, project: project) }

    include_examples 'when the user can read the awardable'
    include_examples 'when the user cannot read the awardable'
  end

  context 'when the awardable is a snippet' do
    let(:awardable) { create(:project_snippet, :public, project: project) }

    include_examples 'when the user can read the awardable'
    include_examples 'when the user cannot read the awardable'
  end
end
