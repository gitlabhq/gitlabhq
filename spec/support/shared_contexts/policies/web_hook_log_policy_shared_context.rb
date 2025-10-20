# frozen_string_literal: true

RSpec.shared_examples 'a webhook log policy' do
  let_it_be(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  context 'when the user is authorized' do
    subject(:policy) { described_class.new(authorized_user, web_hook_log) }

    it "can read and admin web-hooks" do
      expect(policy).to be_allowed(:read_web_hook)
      expect(policy).to be_allowed(:admin_web_hook)
    end
  end

  context 'when the user is not authorized' do
    subject(:policy) { described_class.new(unauthorized_user, web_hook_log) }

    it "cannot read and admin web-hooks" do
      expect(policy).to be_disallowed(:read_web_hook)
      expect(policy).to be_disallowed(:admin_web_hook)
    end
  end
end
