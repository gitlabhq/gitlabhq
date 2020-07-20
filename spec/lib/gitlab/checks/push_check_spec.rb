# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::PushCheck do
  include_context 'change access checks context'

  describe '#validate!' do
    it 'does not raise any error' do
      expect { subject.validate! }.not_to raise_error
    end

    context 'when the user is not allowed to push to the repo' do
      it 'raises an error' do
        expect(user_access).to receive(:can_do_action?).with(:push_code).and_return(false)
        expect(project).to receive(:branch_allows_collaboration?).with(user_access.user, 'master').and_return(false)

        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, 'You are not allowed to push code to this project.')
      end
    end
  end
end
