# coding: utf-8
# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  email             :string(255)      not null
#  created_at        :datetime
#  updated_at        :datetime
#  subscribed        :boolean          default(TRUE)
#  unsubscribe_token :string(255)      not null
#  timezone          :string(255)      not null
#  language          :string(255)      not null
#  email_verified    :boolean          default(FALSE), not null
#  alert_time        :string(255)      default("08:00"), not null
#

require 'securerandom'

class TimezoneValidator
  def include? timezone
    case timezone
    when ActiveSupport::TimeZone
      User.timezones.include? timezone.identifier
    when String
      User.timezones.include? timezone
    else
      false
    end
  end
end

class User < ActiveRecord::Base
  VALID_EMAIL_REGEXP = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  ALERT_PLACEHOLDER_DAY = '2014-01-01'

  def self.timezones
    ActiveSupport::TimeZone.all.map{ |tz| tz.identifier }.uniq
  end

  def self.languages
    ['zh-Hans-CN', 'zh-Hant-TW', 'en']
  end

  validates :email,      presence: true, format: { with: VALID_EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :timezone,   presence: true, inclusion: { in: TimezoneValidator.new }
  validates :language,   presence: true, inclusion: { in: languages }
  validates :alert_time, presence: true

  has_many :mail_receivers
  has_many :notes, through: :mail_receivers

  pattr_writer :subscribed, :unsubscribe_token

  before_save { self.email = email.downcase }

  # ActiveRecord 在实例化 User 的时候，subscribed 是有默认值的，但此时
  # unsubscribe_token 还是空的，所以需要额外检查一下
  after_initialize { generate_unsubscribe_token if unsubscribe_token.nil? }

  scope :alertable, -> (time = Time.now) do
    case time
    when Time, DateTime
      utc_time = time.in_time_zone 'UTC'
    when String
      utc_time = ActiveSupport::TimeZone['UTC'].parse time
    else
      raise ArgumentError, 'User.alertable only handle Time, DateTime, String instance'
    end

    query_string = ActiveSupport::TimeZone.all.map{ |tz|
      alert_time = utc_time.in_time_zone(tz).strftime '%H:00'
      "(timezone = '#{tz.identifier}' AND alert_time = '#{alert_time}')"
    }.join ' OR '

    where(email_verified: true).where(query_string)
  end

  def random_diary
    return if notes.empty?
    mail_receivers.where('notes_count > 0').sample
  end

  def unsubscribe_link
    return if new_record?
    host_domain = Rails.application.config.mailer_info[:domain]
    # http://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html
    # http://stackoverflow.com/questions/341143/can-rails-routing-helpers-i-e-mymodel-pathmodel-be-used-in-models
    path = Rails.application.routes.url_helpers.subscription_user_path(
      _method: :delete,
      token: "unsubscribe #{unsubscribe_token}",
      id: id,
      action: :unsubscribe
    )
    "#{host_domain}#{path}"
  end

  def unsubscribe_email_address
    return if new_record?
    host_domain = Rails.application.config.mailer_info[:domain]
    "unsubscribe+#{unsubscribe_token}@#{host_domain}"
  end

  def unsubscribe_email_header
    return if new_record?
    "<mailto:#{unsubscribe_email_address}>, <http://#{unsubscribe_link}>"
  end

  def subscribe
    return if subscribed
    self.subscribed = true
    generate_unsubscribe_token
  end

  def unsubscribe **options
    valid = options[:token] == unsubscribe_token
    return false unless valid
    return unless subscribed
    self.subscribed = false
    true
  end

  def timezone
    return unless identifier = read_attribute(:timezone)
    ActiveSupport::TimeZone[identifier]
  end

  def timezone= input_timezone
    if input_timezone.instance_of? ActiveSupport::TimeZone
      input_timezone = input_timezone.identifier
    end
    unless User.timezones.include? input_timezone
      input_timezone = nil
    end
    write_attribute :timezone, input_timezone
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.hex
  end
end
