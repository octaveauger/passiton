class AuthorisationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  default from: "octave@gocardless.com"

  # Send a request for access to the granter
  def request_authorisation(authorisation)
    @authorisation = authorisation

    mail(to: @authorisation.granter.email, subject: 'Passiton - Request for access') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is granted
  def authorisation_granted(authorisation)
    @authorisation = authorisation

    mail(to: @authorisation.requester.email, subject: 'Passiton - Access granted') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is denied
  def authorisation_denied(authorisation)
    @authorisation = authorisation

    mail(to: @authorisation.requester.email, subject: 'Passiton - Access denied') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is revoked
  def authorisation_revoked(authorisation)
    @authorisation = authorisation

    mail(to: @authorisation.requester.email, subject: 'Passiton - Access revoked') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end
end
