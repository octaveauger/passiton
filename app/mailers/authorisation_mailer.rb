class AuthorisationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  #default from: "octave.auger@gmail.com"

  # Send a request for access to the granter
  def request_authorisation(authorisation)
    @authorisation = authorisation

    mail(from: @authorisation.requester.email, to: @authorisation.granter.email, subject: 'Passiton - Context request: ' + @authorisation.scope) do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is granted
  def authorisation_granted(authorisation)
    @authorisation = authorisation

    mail(from: @authorisation.granter.email, to: @authorisation.requester.email, subject: 'Passiton - Context given: ' + @authorisation.scope) do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is denied
  def authorisation_denied(authorisation)
    @authorisation = authorisation

    mail(from: @authorisation.granter.email, to: @authorisation.requester.email, subject: 'Passiton - Context denied: ' + @authorisation.scope) do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notify a requester that their authorisation is revoked
  def authorisation_revoked(authorisation)
    @authorisation = authorisation

    mail(from: @authorisation.granter.email, to: @authorisation.requester.email, subject: 'Passiton - Context revoked: ' + @authorisation.scope) do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end
end
