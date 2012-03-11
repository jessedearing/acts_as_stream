require 'uuidtools'
FactoryGirl.define do

  factory :user do
    sequence(:name) { |i| "Regular User #{i}" }
  end

  factory :admin do
    sequence(:guid) { UUIDTools::UUID.random_create.to_str }
  end

  factory :thing do
    sequence(:name) { |i| "Thing #{i}" }
  end

  factory :widget do
    sequence(:name) { |i| "Widget #{i}" }
  end

end