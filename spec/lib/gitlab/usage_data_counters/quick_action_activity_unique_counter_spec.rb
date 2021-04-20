# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::QuickActionActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }
  let(:note) { build(:note, author: user) }
  let(:args) { nil }

  shared_examples_for 'a tracked quick action unique event' do
    specify do
      expect { 3.times { subject } }
        .to change {
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
            event_names: action,
            start_date: 2.weeks.ago,
            end_date: 2.weeks.from_now
          )
        }
        .by(1)
    end
  end

  subject { described_class.track_unique_action(quickaction_name, args: args, user: user) }

  describe '.track_unique_action' do
    let(:quickaction_name) { 'approve' }

    it_behaves_like 'a tracked quick action unique event' do
      let(:action) { 'i_quickactions_approve' }
    end
  end

  context 'tracking assigns' do
    let(:quickaction_name) { 'assign' }

    context 'single assignee' do
      let(:args) { '@one' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_assign_single' }
      end
    end

    context 'multiple assignees' do
      let(:args) { '@one @two' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_assign_multiple' }
      end
    end

    context 'assigning "me"' do
      let(:args) { 'me' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_assign_self' }
      end
    end

    context 'assigning a reviewer' do
      let(:quickaction_name) { 'assign_reviewer' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_assign_reviewer' }
      end
    end

    context 'assigning a reviewer with request review alias' do
      let(:quickaction_name) { 'request_review' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_assign_reviewer' }
      end
    end
  end

  context 'tracking copy_metadata' do
    let(:quickaction_name) { 'copy_metadata' }

    context 'for issues' do
      let(:args) { '#123' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_copy_metadata_issue' }
      end
    end

    context 'for merge requests' do
      let(:args) { '!123' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_copy_metadata_merge_request' }
      end
    end
  end

  context 'tracking spend' do
    let(:quickaction_name) { 'spend' }

    context 'adding time' do
      let(:args) { '1d' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_spend_add' }
      end
    end

    context 'removing time' do
      let(:args) { '-1d' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_spend_subtract' }
      end
    end
  end

  context 'tracking spent' do
    let(:quickaction_name) { 'spent' }

    context 'adding time' do
      let(:args) { '1d' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_spend_add' }
      end
    end

    context 'removing time' do
      let(:args) { '-1d' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_spend_subtract' }
      end
    end
  end

  context 'tracking unassign' do
    let(:quickaction_name) { 'unassign' }

    context 'unassigning everyone' do
      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_unassign_all' }
      end
    end

    context 'unassigning specific users' do
      let(:args) { '@hello' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_unassign_specific' }
      end
    end
  end

  context 'tracking unlabel' do
    context 'called as unlabel' do
      let(:quickaction_name) { 'unlabel' }

      context 'removing all labels' do
        it_behaves_like 'a tracked quick action unique event' do
          let(:action) { 'i_quickactions_unlabel_all' }
        end
      end

      context 'removing specific labels' do
        let(:args) { '~wow' }

        it_behaves_like 'a tracked quick action unique event' do
          let(:action) { 'i_quickactions_unlabel_specific' }
        end
      end
    end

    context 'called as remove_label' do
      let(:quickaction_name) { 'remove_label' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_unlabel_all' }
      end
    end
  end

  context 'tracking invite_email' do
    let(:quickaction_name) { 'invite_email' }

    context 'single email' do
      let(:args) { 'someone@gitlab.com' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_invite_email_single' }
      end
    end

    context 'multiple emails' do
      let(:args) { 'someone@gitlab.com another@gitlab.com' }

      it_behaves_like 'a tracked quick action unique event' do
        let(:action) { 'i_quickactions_invite_email_multiple' }
      end
    end
  end
end
