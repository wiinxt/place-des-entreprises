# frozen_string_literal: true

FactoryBot.define do
  factory :need do
    association :diagnosis
    association :subject

    factory :need_with_matches do
      before(:create) do |need, _|
        need.matches = create_list(:match, 1, need: need)
      end
    end

    after(:create) do |need, _|
      if need.matches.present?
        need.diagnosis.update_columns(step: :completed)
      end
    end
  end
end
