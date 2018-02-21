require "da_spec"
require "../src/da_session"
extend DA_SPEC

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

def new_session(ctx : HTTP::Server::Context | Symbol = :default)
  DA_Session.new(
    (ctx.is_a?(Symbol) ? new_context : ctx),
    secret: SECRET
  )
end

def stranger(method : String = "GET", path : String = "/")
  HTTP::Server::Context.new(
    HTTP::Request.new(method, path, HTTP::Headers.new),
    HTTP::Server::Response.new(IO::Memory.new)
  )
end

def member(
  method : String = "GET",
  path : String = "/",
  cookie_name : String | Symbol = :default,
  cookie_value : String | Symbol = :default
)
  sess = new_session
  sess.save
  headers = HTTP::Headers.new
  cookies = HTTP::Cookies.new
  cookies << HTTP::Cookie.new(
     (cookie_name.is_a?(Symbol) ? sess.cookie_name : cookie_name),
     (cookie_value.is_a?(Symbol) ? sess.encoded_id(sess.id) : cookie_value)
  )
  cookies.add_request_headers(headers)

  HTTP::Server::Context.new(
    HTTP::Request.new(method, path, headers),
    HTTP::Server::Response.new(IO::Memory.new)
  )
end # === def new_member


describe ".encoded_id" do
  it "should use the same session_id" do
    sess = new_session
    sess.save
    assert sess.encoded_id(sess.id) == new_session.encoded_id(sess.id)
  end

  it "should raise SecretRequiredException if secret is not set" do
    assert_raises(DA_Session::Invalid_Secret) do
      DA_Session.new( new_context, secret: "abc" )
    end
  end

  it "should return a new session if signed token has been tampered" do
    sess = new_session
    sess.save
    id = sess.id
    val = "abc#{sess.encoded_id(id)[3..-1]}"
    m = member(cookie_value: "#{id},#{val}")

    actual = new_session(m)
    assert actual.deleted? == true
  end

end # === desc "DA_Session"

