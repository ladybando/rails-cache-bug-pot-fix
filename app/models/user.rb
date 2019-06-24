class User < ApplicationRecord
  include ActiveRecordMarshalable
  has_one_attached :avatar
end
