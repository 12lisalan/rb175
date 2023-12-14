ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    files = ["about.txt", "changes.txt", "history.txt"]
    files.each{|file| assert_includes last_response.body, file}
  end

  def test_txt
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]

    text_body = File.read("data/history.txt")
    assert_includes last_response.body, text_body
  end

  def test_no_file
    get "/some_file"
    assert_equal 302, last_response.status

    get "/"
    assert_includes last_response.body, "some_file does not exist."

    get "/"
    refute_includes last_response.body, "some_file does not exist."
  end
end