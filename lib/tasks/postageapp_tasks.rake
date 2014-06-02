namespace :postageapp do

  desc 'Verify postageapp gem installation by requesting project info from PostageApp.com'
  task :test => :environment do

    puts "Attempting to contact #{PostageApp.configuration.host} ..."
    response = PostageApp::Request.new(:get_project_info).send

    if response.ok?
      project_name  = response.data['project']['name']
      project_url   = response.data['project']['url']
      user_emails   = response.data['project']['users']

      puts %{
  Found Project:
  ----------------------------
   Name:  #{ project_name }
    URL:  #{ project_url }
  Users:  #{ user_emails.keys.join(', ') }
      }

      # Sending test email to all users in the project
      # Most likely a single user if it's a new project
      puts 'Sending test message to users in the project...'
      r = send_test_message(user_emails)
      if r.ok?
        puts "Message was successfully sent!\n\n"
        puts 'Your application is ready to use PostageApp!'
      else
        puts 'Failed to send test message. Please try again. Check logs if issue persists.'
        puts 'This was the response:'
        puts r.to_yaml
      end

    else
      puts 'Failed to fetch information about your project. This was the response:'
      puts response.to_yaml
    end
  end

  desc 'Manually trigger resend of all failed emails'
  task :resend_failed_emails => :environment do
    puts 'Attempting to resend failed emails...'
    PostageApp::FailedRequest.resend_all
    puts 'Done!'
  end

end

HTML_MESSAGE = %{
<h3> Hello {{name}}, </h3>
<p> This is a html message generated by Postage plugin. </p>
<p> If you received this message it means that your application is properly configured and is ready to use PostageApp service. </p>
<p> Thank you, </p>
<p> The PostageApp Team </p>
}

TEXT_MESSAGE = %{
Hello {{name}}

This is a plain text message generated by Postage plugin.
If you received this message it means that your application is properly configured and is ready to use PostageApp service.

Thank you,
The PostageApp Team
}

def send_test_message(recipients)
  recipients_with_variables = {}
  recipients.each do |email, name|
    recipients_with_variables[email] = { 'name' => name }
  end

  PostageApp::Request.new(:send_message,
    :message => {
      'text/html'  => HTML_MESSAGE,
      'text/plain' => TEXT_MESSAGE
    },
    :recipients => recipients_with_variables,
    :headers    => {
      'Subject' => '[PostageApp] Test Message',
      'From'    => 'no-return@postageapp.com'
    }
  ).send
end
