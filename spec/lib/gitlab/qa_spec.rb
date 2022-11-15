# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Qa do
  describe '.request?' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :request_user_agent, :qa_user_agent, :result) do
      false | 'qa_user_agent' | 'qa_user_agent' | false
      true  | nil             | 'qa_user_agent' | false
      true  | ''              | 'qa_user_agent' | false
      true  | 'qa_user_agent' | ''              | false
      true  | 'qa_user_agent' | nil             | false
      true  | 'qa_user_agent' | 'qa_user_agent' | true
    end

    with_them do
      before do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        stub_env('GITLAB_QA_USER_AGENT', qa_user_agent)
      end

      subject { described_class.request?(request_user_agent) }

      it { is_expected.to eq(result) }
    end
  end
end
