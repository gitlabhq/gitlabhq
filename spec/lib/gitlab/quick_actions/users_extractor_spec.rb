# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QuickActions::UsersExtractor do
  subject(:extractor) { described_class.new(current_user, project: project, group: group, target: target, text: text) }

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target) { create(:issue, project: project) }

  let_it_be(:pancakes) { create(:user, username: 'pancakes') }
  let_it_be(:waffles) { create(:user, username: 'waffles') }
  let_it_be(:syrup) { create(:user, username: 'syrup') }

  before do
    allow(target).to receive(:allows_multiple_assignees?).and_return(false)
  end

  context 'when the text is nil' do
    let(:text) { nil }

    it 'returns an empty array' do
      expect(extractor.execute).to be_empty
    end
  end

  context 'when the text is blank' do
    let(:text) { '   ' }

    it 'returns an empty array' do
      expect(extractor.execute).to be_empty
    end
  end

  context 'when there are users to be found' do
    context 'when using usernames' do
      let(:text) { 'me, pancakes waffles and syrup' }

      it 'finds the users' do
        expect(extractor.execute).to contain_exactly(current_user, pancakes, waffles, syrup)
      end
    end

    context 'when there are too many users' do
      let(:text) { 'me, pancakes waffles and syrup' }

      before do
        stub_const("#{described_class}::MAX_QUICK_ACTION_USERS", 2)
      end

      it 'complains' do
        expect { extractor.execute }.to raise_error(described_class::TooManyError)
      end
    end

    context 'when using references' do
      let(:text) { 'me, @pancakes @waffles and @syrup' }

      it 'finds the users' do
        expect(extractor.execute).to contain_exactly(current_user, pancakes, waffles, syrup)
      end
    end

    context 'when using a mixture of usernames and references' do
      let(:text) { 'me, @pancakes waffles and @syrup' }

      it 'finds the users' do
        expect(extractor.execute).to contain_exactly(current_user, pancakes, waffles, syrup)
      end
    end

    context 'when one or more users cannot be found' do
      let(:text) { 'me, @bacon @pancakes, chicken waffles and @syrup' }

      it 'reports an error' do
        expect { extractor.execute }.to raise_error(described_class::MissingError, include('bacon', 'chicken'))
      end
    end

    context 'when trying to find group members' do
      let(:group) { create(:group, path: 'breakfast-foods') }
      let(:text) { group.to_reference }

      it 'reports an error' do
        [pancakes, waffles].each { group.add_developer(_1) }

        expect { extractor.execute }.to raise_error(described_class::MissingError, include('breakfast-foods'))
      end
    end
  end
end
