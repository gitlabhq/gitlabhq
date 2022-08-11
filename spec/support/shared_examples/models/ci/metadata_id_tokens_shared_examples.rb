# frozen_string_literal: true

RSpec.shared_examples_for 'has ID tokens' do |ci_type|
  subject(:ci) { FactoryBot.build(ci_type) }

  describe 'delegations' do
    it { is_expected.to delegate_method(:id_tokens).to(:metadata).allow_nil }
  end

  describe '#id_tokens?' do
    subject { ci.id_tokens? }

    context 'without metadata' do
      let(:ci) { FactoryBot.build(ci_type) }

      it { is_expected.to be_falsy }
    end

    context 'with metadata' do
      let(:ci) { FactoryBot.build(ci_type, metadata: FactoryBot.build(:ci_build_metadata, id_tokens: id_tokens)) }

      context 'when ID tokens exist' do
        let(:id_tokens) { { TEST_JOB_JWT: { id_token: { aud: 'developers ' } } } }

        it { is_expected.to be_truthy }
      end

      context 'when ID tokens do not exist' do
        let(:id_tokens) { {} }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#id_tokens=' do
    it 'assigns the ID tokens to the CI job' do
      id_tokens = [{ 'JOB_ID_TOKEN' => { 'id_token' => { 'aud' => 'https://gitlab.test ' } } }]
      ci.id_tokens = id_tokens

      expect(ci.id_tokens).to match_array(id_tokens)
    end
  end
end
