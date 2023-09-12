require "js"

def document
  @document ||= JS.global[:document]
end

def validate_phone(text)
  cond = text.match?(/\A0\d{10}\Z/)
  err = document.getElementById("error")
  if cond
    err[:innerText] = ""
  else
    err[:innerText] = "NG"
  end
end

input = document.getElementById("phone")

input.addEventListener "change" do |e|
  validate_phone(e[:target][:value].to_s)
end
