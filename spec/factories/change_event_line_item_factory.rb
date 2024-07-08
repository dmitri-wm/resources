# frozen_string_literal: true

# domain: Change Events

FactoryBot.define do
  factory :change_event, class: "ChangeEvent" do
    number { "Faker::IDNumber" }
  end

  factory :commitment_contract, class: "Contract" do
    name { "Commitment #{Faker::Lorem.word}" }
    contract_type { "commitment" }
  end

  factory :prime_contract, class: "Contract" do
    name { "Prime #{Faker::Lorem.word}" }
    contract_type { "prime" }
  end

  factory :potential_change_order, class: "PotentialChangeOrder" do
    status { %w[Open Draft Closed].shuffle }
  end

  factory :prime_potential_change_order, class: "PotentialChangeOrder" do
    association :contract, factory: :prime_contract
  end

  factory :commitment_potential_change_order, class: "PotentialChangeOrder" do
    association :contract, factory: :commitment_contract
  end

  factory :prime_potential_change_order_line_itemm, class: "LineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    association :holder, factory: :prime_potential_change_order
  end

  factory :commitment_potential_change_order_line_itemm, class: "LineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    association :holder, factory: :commitment_potential_change_order
  end

  factory :change_event_line_item, class: "ChangeEventLineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }

    association :change_event

    trait :with_ppco do
      association :prime_potential_change_order_line_item
    end

    trait :with_cc do
      association :commitment_contract_line_item
    end

    trait :with_ccpco do
      association :commitment_potential_change_order_line_item
    end
  end
end
