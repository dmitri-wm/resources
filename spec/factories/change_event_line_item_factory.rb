# frozen_string_literal: true

# domain: Change Events

FactoryBot.define do
  factory :change_event, class: "ChangeEvent" do
    number { "Faker::IDNumber" }
    project_id { 1 }
    company_id { 1 }
  end

  factory :commitment_contract, class: "Contract" do
    name { "Commitment #{Faker::Lorem.word}" }
    contract_type { "commitment" }
     project_id { 1 }
    company_id { 1 }
  end

  factory :prime_contract, class: "Contract" do
    name { "Prime #{Faker::Lorem.word}" }
    contract_type { "prime" }
    project_id { 1 }
    company_id { 1 }
  end

  factory :potential_change_order, class: "PotentialChangeOrder" do
    status { %w[Open Draft Closed].shuffle }
    project_id { 1 }
    company_id { 1 }
  end

  factory :prime_potential_change_order, class: "PotentialChangeOrder" do
    association :contract, factory: :prime_contract
    project_id { 1 }
    company_id { 1 }
  end

  factory :commitment_potential_change_order, class: "PotentialChangeOrder" do
    association :contract, factory: :commitment_contract
    project_id { 1 }
    company_id { 1 }
  end

  factory :prime_potential_change_order_line_itemm, class: "LineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    association :holder, factory: :prime_potential_change_order
    project_id { 1 }
    company_id { 1 }
  end

  factory :commitment_potential_change_order_line_itemm, class: "LineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    association :holder, factory: :commitment_potential_change_order
    project_id { 1 }
    company_id { 1 }
  end

  factory :change_event_line_item, class: "ChangeEventLineItem" do
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }

    association :change_event
    project_id { 1 }
    company_id { 1 }

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
