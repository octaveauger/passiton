require "spec_helper"

describe AuthorisationMailer do
  describe "request_authorisation" do
    let(:mail) { AuthorisationMailer.request_authorisation }

    it "renders the headers" do
      mail.subject.should eq("Request authorisation")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "authorisation_granted" do
    let(:mail) { AuthorisationMailer.authorisation_granted }

    it "renders the headers" do
      mail.subject.should eq("Authorisation granted")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "authorisation_denied" do
    let(:mail) { AuthorisationMailer.authorisation_denied }

    it "renders the headers" do
      mail.subject.should eq("Authorisation denied")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "authorisation_revoked" do
    let(:mail) { AuthorisationMailer.authorisation_revoked }

    it "renders the headers" do
      mail.subject.should eq("Authorisation revoked")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
