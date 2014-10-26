require "rails_helper"

mail_info = Rails.application.config.mailer_info

describe DiaryMailer, :type => :mailer do
  describe '.daily' do
    let(:mail) do
      @user = create :user
      DiaryMailer.daily @user
    end

    it 'send a daily email to user' do
      expect(mail).to have_subject 'diary_mailer.daily.subject'
      expect(mail).to reply_to "#{@user.mail_receivers.first.address}@#{mail_info[:domain]}"
      expect(mail).to deliver_to @user.email
      expect(mail).to deliver_from "#{mail_info[:nickname]} <#{mail_info[:deliverer]}@#{mail_info[:domain]}>"
      expect(mail).to have_header 'List-Unsubscribe', "<http://#{mail_info[:domain]}#{@user.unsubscribe_path}>"
      expect(mail.mailgun_headers).to eq 'List-Unsubscribe' => "<http://#{mail_info[:domain]}#{@user.unsubscribe_path}>"
    end
  end
end
