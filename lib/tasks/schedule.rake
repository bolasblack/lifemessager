
def log task_name, content
  puts "[schedule:#{task_name}] (#{Time.now.inspect}) #{content}"
end

namespace :schedule do

desc 'Send mail to current hour alertable users'
task :mail_hourly => :environment do
  if User.alertable.empty?
    log 'mail_hourly', 'No alertable user'
    return
  end
  log 'mail_hourly', 'Alert user started'
  User.alertable.find_each do |user|
    begin
      DiaryMailer.daily(user).deliver!
      log 'mail_hourly', "Alert user #{user.email} finished"
    rescue => error
      log 'mail_hourly', "Alert user #{user.email} failed: \n #{error.backtrace.join "\n"}"
    end
  end
  log 'mail_hourly', 'Alert user all finished'
end

end
