# == Schema Information
#
# Table name: notes
#
#  id               :integer          not null, primary key
#  from_email       :string(255)      not null
#  content          :text             not null
#  created_at       :datetime
#  updated_at       :datetime
#  mail_receiver_id :integer          not null
#

class Note < ActiveRecord::Base
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :from_email   , presence: true, format: { with: VALID_EMAIL_REGEX }
  validates :content      , presence: true
  validates :mail_receiver, presence: true

  belongs_to :mail_receiver

  def note_date
    mail_receiver.note_date
  end

  def user
    mail_receiver.user
  end
end
