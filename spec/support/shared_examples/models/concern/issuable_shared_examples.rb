# frozen_string_literal: true

shared_examples_for 'matches_cross_reference_regex? fails fast' do
  it 'fails fast for long strings' do
    # took well under 1 second in CI https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3267#note_172823
    expect do
      Timeout.timeout(6.seconds) { mentionable.matches_cross_reference_regex? }
    end.not_to raise_error
  end
end

shared_examples_for 'validates description length with custom validation' do
  let(:issuable) { build(:issue, description: 'x' * (::Issuable::DESCRIPTION_LENGTH_MAX + 1)) }
  let(:context) { :update }

  subject { issuable.validate(context) }

  context 'when Issuable is a new record' do
    it 'validates the maximum description length' do
      subject
      expect(issuable.errors[:description]).to eq(["is too long (maximum is #{::Issuable::DESCRIPTION_LENGTH_MAX} characters)"])
    end

    context 'on create' do
      let(:context) { :create }

      it 'does not validate the maximum description length' do
        allow(issuable).to receive(:description_max_length_for_new_records_is_valid).and_call_original

        subject

        expect(issuable).not_to have_received(:description_max_length_for_new_records_is_valid)
      end
    end
  end

  context 'when Issuable is an existing record' do
    before do
      allow(issuable).to receive(:expire_etag_cache) # to skip the expire_etag_cache callback

      issuable.save!(validate: false)
    end

    it 'does not validate the maximum description length' do
      subject
      expect(issuable.errors).not_to have_key(:description)
    end
  end
end

shared_examples_for 'truncates the description to its allowed maximum length on import' do
  before do
    allow(issuable).to receive(:importing?).and_return(true)
  end

  let(:issuable) { build(:issue, description: 'x' * (::Issuable::DESCRIPTION_LENGTH_MAX + 1)) }

  subject { issuable.validate(:create) }

  it 'truncates the description to its allowed maximum length' do
    subject

    expect(issuable.description).to eq('x' * ::Issuable::DESCRIPTION_LENGTH_MAX)
    expect(issuable.errors[:description]).to be_empty
  end
end
