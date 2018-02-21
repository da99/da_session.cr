require "da_spec"
require "inspect_bang"
require "../src/da_session"

# =============================================================================
# Helpers
# =============================================================================

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

# =============================================================================
# Specifications
# =============================================================================

describe ".new(..)" do
  it "should mark session as (:new? == false)" do
    sess = new_session
    assert sess.new? == false
  end # === it "marks session as (:new? == false)"
end # === desc ".new(..)"

describe "attribute secret" do

  it "should raise Invalid_Secret if secret is not set" do
    assert_raises(DA_Session::Invalid_Secret) do
      DA_Session.new( new_context, secret: "abc" )
    end
  end

end # === desc "secret"

describe ".load" do

  it "should mark the session (:deleted? == true) if signed token was tampered" do
    sess = new_session
    sess.save
    id  = sess.id
    val = "abc#{sess.encoded_id(id)[3..-1]}"
    m   = member(cookie_value: "#{id},#{val}")

    actual = new_session(m)
    actual.load
    assert actual.deleted? == true
  end

  it "should send a Cookie response of an empty string if signed token was tampered" do
    sess = new_session
    sess.save
    id  = sess.id
    val = "abc#{sess.encoded_id(id)[3..-1]}"
    m   = member(cookie_value: "#{id},#{val}")

    actual = new_session(m)
    actual.load
    assert m.response.cookies[sess.cookie_name].value == ""
  end

end # === desc ".load"

describe ".encoded_id" do

  it "should use the same session_id" do
    sess = new_session
    sess.save
    assert sess.encoded_id(sess.id) == new_session.encoded_id(sess.id)
  end

end # === desc "DA_Session"

describe ".save" do
  it "should mark session as (:new? == true)" do
    sess = new_session
    sess.save
    assert sess.new? == true
  end # === it "should mark session as (:new? == true)"
end # === desc ".save"

