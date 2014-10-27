class MailsController < ApplicationController
  skip_before_action :verify_token

  def notes
    mail_receiver = MailReceiver.find_by_address get_receiver_address params['recipient']

    note = mail_receiver.notes.build(
      from_email: params['sender'],
      content: params['stripped-text'],
      mail_receiver: mail_receiver,
      created_at: params['Date']
    )

    if note.save
      simple_respond nil, status: :created
    else
      puts 'note save error'
      puts note.errors
      simple_respond nil, status: :internal_server_error
    end
  end

  private

  def get_receiver_address(mail)
    mail[/^([^@]+).*$/, 1]
  end
end
