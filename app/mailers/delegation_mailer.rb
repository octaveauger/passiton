class DelegationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic

  # Send a request for delegation to an employee
  def request_delegation(delegation)
    @delegation = delegation

    mail(from: @delegation.manager.email, to: @delegation.employee.email, subject: 'Passiton - Delegation request') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Confirms a request for delegation from an employee
  def confirm_delegation(delegation)
  	@delegation = delegation

    mail(from: @delegation.employee.email, to: @delegation.manager.email, subject: 'Passiton - Delegation confirmed') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
  	end
  end

  # Notifies a manager that a delegation was revoked by the employee
  def revoke_delegation(delegation)
    @delegation = delegation

    mail(from: @delegation.employee.email, to: @delegation.manager.email, subject: 'Passiton - Delegation revoked') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

  # Notifies an employee that a delegation was cancelled by the manager
  def cancel_delegation(delegation)
    @delegation = delegation

    mail(from: @delegation.manager.email, to: @delegation.employee.email, subject: 'Passiton - Delegation cancelled') do |format|
      format.html { render layout: 'email_simple.html.erb' }
      format.text
    end
  end

end
