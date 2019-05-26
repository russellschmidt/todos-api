class User < ApplicationRecord
  #encrypt password see gem file, bcrypt method
  has_secure_password

  has_many :todos, foreign_key: :created_by

  validates_presence_of :name, :email, :password_digest

end
