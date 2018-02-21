require "da_spec"
require "../src/da_session"

SECRET = "The cat nimbled my homeWork, Teach'."

def new_id
  Random::Secure.hex
end

def new_context(method : String = "GET", path : String = "/")
  HTTP::Server::Context.new(
    HTTP::Request.new(method, path, HTTP::Headers.new),
    HTTP::Server::Response.new(IO::Memory.new)
  )
end # === def new_member

def new_session
  DA_Session.new(new_context, secret: SECRET)
end

def stranger(method : String = "GET", path : String = "/")
  HTTP::Server::Context.new(
    HTTP::Request.new(method, path, HTTP::Headers.new),
    HTTP::Server::Response.new(IO::Memory.new)
  )
end

def member(method : String = "GET", path : String = "/")
  sess = new_session
  sess.save
  headers = HTTP::Headers.new
  cookies = HTTP::Cookies.new
  cookies << HTTP::Cookie.new(
    sess.cookie_name, sess.encoded_id(sess.id)
  )
  cookies.add_request_headers(headers)

  HTTP::Server::Context.new(
    HTTP::Request.new(method, path, headers),
    HTTP::Server::Response.new(IO::Memory.new)
  )
end # === def new_member

describe "DA_Session" do
#   it "should use the same session_id" do
#   it "should return a new session if signed token has been tampered" do
#   it "should raise SecretRequiredException if secret is not set" do
end # === desc "DA_Session"
