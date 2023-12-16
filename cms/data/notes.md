#### Questions:
Relationship between session and <%== yield %>? Why does it work after I use session?

#### Methods:
Minitest:
`assert(true)`
`assert_equal 200, last_response.status`
`assert_includes last_response.body, "about.txt"`
#### Notes:
`session` Hash
- used to access data between requests
- need to enable session before using:
```ruby
# cms.rb
configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

set :session_secret, SecureRandom.hex(32)

```

Converting Markdown into HTML:
`redcarpet`
- need to add to Gemfile
- add `require "redcarpet"` to application
```ruby
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
markdown.render("# This will be a headline!")
```



---
Notes for assignment:
when user view non-existent document, direct to index and display "$DOCUMENT does not exist."
- after reloading page, error message should disappear
- check direct and load error message
test



error:
- session error wouldn't appear
solution:
- need to enable session before data can persist
lesson:
- check file using ctrl-f to understand code better