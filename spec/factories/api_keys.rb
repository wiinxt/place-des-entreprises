# frozen_string_literal: true

FactoryBot.define do
  factory :api_key do
    association :institution
    sequence(:token) { |n| Faker::Lorem.word + n.to_s }
  end
end
