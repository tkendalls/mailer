namespace :mail do
  desc "Send Event Mailer"
  task event_email: :environment do
    emails = %w(
      aboyd@audubon.org
      sjervey@audubon.org
      )

    emails.each do |email|
      PonyExpress.event_email(email).deliver
    end
  end
end