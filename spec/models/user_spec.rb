require 'rails_helper'

RSpec.describe User, type: :model do
  # Association test
  # ensure User model ahs a 1:m relationship with the Todo model
  it { should have_many(:todos) }

  # Validation test
  # make sure the fields are filled in before saving
  it { should validate_presence_of(:name)}
  it { should validate_presence_of(:email)}
  it { should validate_presence_of(:password_digest)}
end
