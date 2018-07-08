require 'spec_helper'

describe Ci::BuildRunnerSession, model: true do
  let!(:build) { create(:ci_build, :with_runner_session) }

  subject { build.runner_session }

  it { is_expected.to belong_to(:build) }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:url).with_message('must be a valid URL') }

  describe '#terminal_specification' do
    let(:terminal_specification) { subject.terminal_specification }

    it 'returns empty hash if no url' do
      subject.url = ''

      expect(terminal_specification).to be_empty
    end

    context 'when url is present' do
      it 'returns ca_pem nil if empty certificate' do
        subject.certificate = ''

        expect(terminal_specification[:ca_pem]).to be_nil
      end

      it 'adds Authorization header if authorization is present' do
        subject.authorization = 'whatever'

        expect(terminal_specification[:headers]).to include(Authorization: 'whatever')
      end
    end
  end
end
