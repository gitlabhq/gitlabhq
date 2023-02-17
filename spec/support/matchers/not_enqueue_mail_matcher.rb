# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_enqueue_mail, :have_enqueued_mail
